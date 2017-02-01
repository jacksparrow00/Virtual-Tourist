//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Nitish on 21/01/17.
//  Copyright © 2017 Nitish. All rights reserved.
//

import Foundation
import CoreData
class FlickrAPI{
    
    func search(pin selectedPin : Pin, managedContext coreDataContext: NSManagedObjectContext,completionHandlerForSearch: @escaping(_ data: AnyObject?,_ error: String?) -> Void){          //give url parameters for flickr api for flickr.photos.search method
        let methodParameters = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
            FlickrParameterKeys.BoundingBox: bboxString(latitude: selectedPin.latitude, longitude: selectedPin.longitude),
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.perPage: FlickrParameterValues.perPage,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback]
        
        displayImageFromFlickr(methodParameters: methodParameters as [String : AnyObject],coreDataContext: coreDataContext,completionHandler: completionHandlerForSearch)
    }
    
     func bboxString(latitude: Double, longitude: Double) -> String{    //give bbox parameters and return string containing boundaries
        let minimumLong = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
        let maximumLong = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
        return "\(minimumLong),\(minimumLat),\(maximumLong),\(maximumLat)"
    }
    
    func displayImageFromFlickr(methodParameters: [String:AnyObject],coreDataContext: NSManagedObjectContext,completionHandler: @escaping(_ data:AnyObject?,_ error: String?) -> Void){
        let request = URLRequest(url: flickrURLFromParameters(parameters: methodParameters))
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in       //start urlsession task
            
            guard error == nil else{            //error handling
                completionHandler(nil,"There was an error from your request \(error?.localizedDescription)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode < 300 else{          //error handling
                completionHandler(nil,"Your request returned a status other than 2xx")
                return
            }
            
            guard let data = data else{         //error handling
                completionHandler(nil,"No data was returned by the request")
                return
            }
            
            let parsedResult: [String:AnyObject]!               //parse into json
            do{
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            }catch{
                completionHandler(nil,"Could not parse the data into json: \(data)")
                return
            }
            
            guard let stat = parsedResult[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else{            //find status key in parsed data
                completionHandler(nil,"Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            guard let photosDictionary = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject] else{               //find photos key in parsed data
                completionHandler(nil,"Cannot find key \(FlickrResponseKeys.Photos) in \(parsedResult)")
                return
            }
            
            guard let totalPages = photosDictionary[FlickrResponseKeys.Pages] as? Int else{     //find pages key in parsed data
                completionHandler(nil,"Cannot find key \(FlickrResponseKeys.Pages)")
                return
            }
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1         //get a random number for getting random page of results
            self.displayImageFromFlickrBySearch(methodParameters, withPageNumber: randomPage,coreDataContext: coreDataContext,completionHandlerForPage: completionHandler)
        }
        task.resume()
    }
    
    func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject], withPageNumber: Int,coreDataContext: NSManagedObjectContext, completionHandlerForPage:@escaping (_ data: AnyObject?,_ error: String?) -> Void) {
        
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(parameters: methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandlerForPage(nil, "There was an error with your request: \(error?.localizedDescription)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode < 300 else {
                completionHandlerForPage(nil,"Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandlerForPage(nil,"No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                completionHandlerForPage(nil,"Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                completionHandlerForPage(nil,"Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandlerForPage(nil,"Cannot find key '\(FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completionHandlerForPage(nil,"Cannot find key '\(FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            if photosArray.count == 0 {
                completionHandlerForPage(nil,"No Photos Found. Search Again.")
                return
            } else {
                for photo in photosArray{
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photo[FlickrResponseKeys.MediumURL] as? String else {
                        completionHandlerForPage(nil,"Cannot find key '\(FlickrResponseKeys.MediumURL)' in \(photo)")
                        return
                    }
                    
                    // if an image exists at the url, set the image
                    coreDataContext.perform {
                        let photo = Photo(context: coreDataContext)
                        
                        print(imageUrlString)
                        
                        photo.url = imageUrlString
                        
                        
                    }
                }
            }
        }
        
        // start the task!
        task.resume()
    }
    
    func downloadImage(imagePath: String, completionHandlerForDownload: @escaping(_ data: NSData?, _ error: String?) -> Void){
        let task = URLSession.shared.dataTask(with: URL(string: imagePath)!) { (data, response, error) in               //start the task to download image
            guard error == nil else{            //error handling
                completionHandlerForDownload(nil, "Your request returned an error: \(error?.localizedDescription)")
                return
            }
            completionHandlerForDownload(data as NSData?,nil)
        }
        task.resume()
    }
    
    /*func getURLForImage(urlString: String, completionHandlerForGetURL: @escaping(_ data: Data?, _ error: String?) -> Void){
        guard let url = URL(string: urlString) else{
            completionHandlerForGetURL(nil,"The image url couldn't be resolved")
            return
        }
        
        guard let imageData = try? Data(contentsOf: url) else{
            completionHandlerForGetURL(nil,"The image data couldn't be downloaded")
            return
        }
        completionHandlerForGetURL(imageData, nil)
    }*/

    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> URL{
        var components = URLComponents()
        components.scheme = Flickr.APIScheme            //define url scheme
        components.host = Flickr.APIHost                //define url host
        components.path = Flickr.APIPath                //define host's path
        components.queryItems = [URLQueryItem]()
        
        for (key,value) in parameters{                  //insert the query items into the url
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem)
        }
        if  components.url == nil               //error handling
        {
            print("Error in URL Creation")
        }
        
        guard let urlrequested = components.url else {          //place holder image call
            print("Error in URL Creation")
            let url2 = NSURL(string: "https://www.flickr.com/photos/flickr/30709520093/in/feed")
            return url2 as! URL
        }
        return urlrequested
    }
    
    class func sharedInstance() -> FlickrAPI{                   //creating a shared instance
        struct Singleton{
            static var sharedInstance = FlickrAPI()
        }
        return Singleton.sharedInstance
    }
}
