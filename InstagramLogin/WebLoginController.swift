//
//  ViewController.swift
//  InstagramLogin
//
//  Created by AJK on 10/18/16.
//  Copyright © 2016 ajk. All rights reserved.
//

import UIKit
import WebKit

protocol WebLoginControllerDelegate {
    func webLoginController(didFinishLogin userDict: NSDictionary)
}

class WebLoginController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    let indicator = UIActivityIndicatorView()
    
    var delegate : WebLoginControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        
        startAuthorization()
        
        indicator.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        indicator.activityIndicatorViewStyle = .large
        indicator.backgroundColor = UIColor.lightText
        indicator.color = UIColor.black
        webView.addSubview(indicator)
        
    }
    
    @IBAction func cancelTap(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Custom Method
    func startAuthorization() {
        // Specify the response type which should always be "code".
        let responseType = "code"
        
        // Set the redirect URL. Adding the percent escape characthers is necessary.
        let redirectURL = Constants().redirectURI.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!
        
        // Set preferred scope.
        //let scope = "r_basicprofile%20r_emailaddress%20w_share"
        
        var authorizationURL = "\(Constants().authorizationEndPoint)?"
        authorizationURL += "response_type=\(responseType)&"
        authorizationURL += "client_id=\(Constants().instagramClientID)&"
        authorizationURL += "redirect_uri=\(redirectURL)&"
        //authorizationURL += "scope=\(scope)"
        
        print(authorizationURL)
        
        // Create a URL request and load it in the web view.
        let request = URLRequest(url: URL(string: authorizationURL)!)
        webView.load(request)
    }
    
    func requestForAccessToken(_ authorizationCode: String) {
        let grantType = "authorization_code"
        
        let redirectURL = Constants().redirectURI.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!
        
        // Set the POST parameters.
        var postParams = "grant_type=\(grantType)&"
        postParams += "code=\(authorizationCode)&"
        postParams += "redirect_uri=\(redirectURL)&"
        postParams += "client_id=\(Constants().instagramClientID)&"
        postParams += "client_secret=\(Constants().instagramSecret)"
        
        // Convert the POST parameters into a NSData object.
        let postData = postParams.data(using: String.Encoding.utf8)
        
        
        // Initialize a mutable URL request object using the access token endpoint URL string.
        var request = URLRequest(url: URL(string: Constants().accessTokenEndPoint)!)
        
        // Indicate that we're about to make a POST request.
        request.httpMethod = "POST"
        
        // Set the HTTP body using the postData object created above.
        request.httpBody = postData
        
        // Add the required HTTP header field.
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        
        
        // Initialize a NSURLSession object.
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        
        // Make the request.
        let task: URLSessionDataTask = session.dataTask(with: request,completionHandler: { (data, response, error) -> Void in
            // Get the HTTP status code of the request.
            if error == nil {
                
                let statusCode = (response as! HTTPURLResponse).statusCode
                
                if statusCode == 200 {
                    // Convert the received JSON data into a dictionary.
                    do {
                        
                        let dataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:Any]
                        
                        let userData = dataDictionary["user"] as? NSDictionary
                        
                        print(dataDictionary)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.indicator.stopAnimating()
                            self.delegate!.webLoginController(didFinishLogin: userData!)
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                    catch {
                        print("Could not convert JSON data into a dictionary.")
                    }
                }
            }
            
            else {
                self.indicator.stopAnimating()
                print(error!.localizedDescription)
                
            }
        })
        
        task.resume()
    }
}

// MARK: - WKNavigationDelegate
extension WebLoginController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        indicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        indicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            print(url.host ?? "")
            
            if url.host == "com.ajk.demo" {
                indicator.startAnimating()
                if url.absoluteString.contains("code") {
                    // Extract the authorization code.
                    let urlParts = url.absoluteString.components(separatedBy: "?")
                    if let code = urlParts[1].components(separatedBy: "=").last {
                        requestForAccessToken(code)
                    }
                }
            }
        }
        decisionHandler(.allow)  // Allow the navigation to proceed
    }
}
