//
//  ViewController.swift
//  YTDemo
//
//  Created by Gabriel Theodoropoulos on 27/6/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tblVideos: UITableView!
    
    @IBOutlet weak var segDisplayedContent: UISegmentedControl!
    
    @IBOutlet weak var viewWait: UIView!
    
    @IBOutlet weak var txtSearch: UITextField!
    
    
    var apiKey = "YOUR_API_KEY_HERE"
    
    var desiredChannelsArray = ["Apple", "Google", "Microsoft"]
    
    var channelIndex = 0
    
    var channelsDataArray: Array<Dictionary<NSObject, AnyObject>> = []
    
    var videosArray: Array<Dictionary<NSObject, AnyObject>> = []
    
    var selectedVideoIndex: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tblVideos.delegate = self
        tblVideos.dataSource = self
        txtSearch.delegate = self
        
        getChannelDetails(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "idSeguePlayer" {
            let playerViewController = segue.destinationViewController as! PlayerViewController
            playerViewController.videoID = videosArray[selectedVideoIndex]["videoID"] as! String
        }
    }
    
    
    // MARK: IBAction method implementation
    
    @IBAction func changeContent(sender: AnyObject) {
        tblVideos.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    
    // MARK: UITableView method implementation
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segDisplayedContent.selectedSegmentIndex == 0 {
            return channelsDataArray.count
        }
        else {
            return videosArray.count
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        if segDisplayedContent.selectedSegmentIndex == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("idCellChannel", forIndexPath: indexPath)
            
            let channelTitleLabel = cell.viewWithTag(10) as! UILabel
            let channelDescriptionLabel = cell.viewWithTag(11) as! UILabel
            let thumbnailImageView = cell.viewWithTag(12) as! UIImageView
            
            let channelDetails = channelsDataArray[indexPath.row]
            channelTitleLabel.text = channelDetails["title"] as? String
            channelDescriptionLabel.text = channelDetails["description"] as? String
            thumbnailImageView.image = UIImage(data: NSData(contentsOfURL: NSURL(string: (channelDetails["thumbnail"] as? String)!)!)!)
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("idCellVideo", forIndexPath: indexPath)
            
            let videoTitle = cell.viewWithTag(10) as! UILabel
            let videoThumbnail = cell.viewWithTag(11) as! UIImageView
            
            let videoDetails = videosArray[indexPath.row]
            videoTitle.text = videoDetails["title"] as? String
            videoThumbnail.image = UIImage(data: NSData(contentsOfURL: NSURL(string: (videoDetails["thumbnail"] as? String)!)!)!)
        }
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 140.0
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if segDisplayedContent.selectedSegmentIndex == 0 {
            // In this case the channels are the displayed content.
            // The videos of the selected channel should be fetched and displayed.
            
            // Switch the segmented control to "Videos".
            segDisplayedContent.selectedSegmentIndex = 1
            
            // Show the activity indicator.
            viewWait.hidden = false
            
            // Remove all existing video details from the videosArray array.
            videosArray.removeAll(keepCapacity: false)
            
            // Fetch the video details for the tapped channel.
            getVideosForChannelAtIndex(indexPath.row)
        }
        else {
            selectedVideoIndex = indexPath.row
            performSegueWithIdentifier("idSeguePlayer", sender: self)
        }
    }
    
    
    // MARK: UITextFieldDelegate method implementation
    
func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    viewWait.hidden = false
    
    // Specify the search type (channel, video).
    var type = "channel"
    if segDisplayedContent.selectedSegmentIndex == 1 {
        type = "video"
        videosArray.removeAll(keepCapacity: false)
    }
    
    // Form the request URL string.
    var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(textField.text)&type=\(type)&key=\(apiKey)"
    urlString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    
    // Create a NSURL object based on the above string.
    let targetURL = NSURL(string: urlString)
    
    // Get the results.
    performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
        if HTTPStatusCode == 200 && error == nil {
            // Convert the JSON data to a dictionary object.
            do {
                let resultsDict = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! Dictionary<NSObject, AnyObject>
                
                // Get all search result items ("items" array).
                let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                
                // Loop through all search results and keep just the necessary data.
                for var i=0; i<items.count; ++i {
                    let snippetDict = items[i]["snippet"] as! Dictionary<NSObject, AnyObject>
                    
                    // Gather the proper data depending on whether we're searching for channels or for videos.
                    if self.segDisplayedContent.selectedSegmentIndex == 0 {
                        // Keep the channel ID.
                        self.desiredChannelsArray.append(snippetDict["channelId"] as! String)
                    }
                    else {
                        // Create a new dictionary to store the video details.
                        var videoDetailsDict = Dictionary<NSObject, AnyObject>()
                        videoDetailsDict["title"] = snippetDict["title"]
                        videoDetailsDict["thumbnail"] = ((snippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
                        videoDetailsDict["videoID"] = (items[i]["id"] as! Dictionary<NSObject, AnyObject>)["videoId"]
                        
                        // Append the desiredPlaylistItemDataDict dictionary to the videos array.
                        self.videosArray.append(videoDetailsDict)
                        
                        // Reload the tableview.
                        self.tblVideos.reloadData()
                    }
                }
            } catch {
                print(error)
            }
            
            // Call the getChannelDetails(…) function to fetch the channels.
            if self.segDisplayedContent.selectedSegmentIndex == 0 {
                self.getChannelDetails(true)
            }
            
        }
        else {
            print("HTTP Status Code = \(HTTPStatusCode)")
            print("Error while loading channel videos: \(error)")
        }
        
        // Hide the activity indicator.
        self.viewWait.hidden = true
    })
    
    
    return true
}
    
    
    // MARK: Custom method implementation
    
    func performGetRequest(targetURL: NSURL!, completion: (data: NSData?, HTTPStatusCode: Int, error: NSError?) -> Void) {
        let request = NSMutableURLRequest(URL: targetURL)
        request.HTTPMethod = "GET"
        
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        let session = NSURLSession(configuration: sessionConfiguration)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(data: data, HTTPStatusCode: (response as! NSHTTPURLResponse).statusCode, error: error)
            })
        })
        
        task.resume()
    }
    
    
    func getChannelDetails(useChannelIDParam: Bool) {
        var urlString: String!
        if !useChannelIDParam {
            urlString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails,snippet&forUsername=\(desiredChannelsArray[channelIndex])&key=\(apiKey)"
        }
        else {
            urlString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails,snippet&id=\(desiredChannelsArray[channelIndex])&key=\(apiKey)"
        }
        
        let targetURL = NSURL(string: urlString)
        
        performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                
                do {
                    // Convert the JSON data to a dictionary.
                    let resultsDict = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! Dictionary<NSObject, AnyObject>
                    
                    // Get the first dictionary item from the returned items (usually there's just one item).
                    let items: AnyObject! = resultsDict["items"] as AnyObject!
                    let firstItemDict = (items as! Array<AnyObject>)[0] as! Dictionary<NSObject, AnyObject>
                    
                    // Get the snippet dictionary that contains the desired data.
                    let snippetDict = firstItemDict["snippet"] as! Dictionary<NSObject, AnyObject>
                    
                    // Create a new dictionary to store only the values we care about.
                    var desiredValuesDict: Dictionary<NSObject, AnyObject> = Dictionary<NSObject, AnyObject>()
                    desiredValuesDict["title"] = snippetDict["title"]
                    desiredValuesDict["description"] = snippetDict["description"]
                    desiredValuesDict["thumbnail"] = ((snippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
                    
                    // Save the channel's uploaded videos playlist ID.
                    desiredValuesDict["playlistID"] = ((firstItemDict["contentDetails"] as! Dictionary<NSObject, AnyObject>)["relatedPlaylists"] as! Dictionary<NSObject, AnyObject>)["uploads"]
                    
                    
                    // Append the desiredValuesDict dictionary to the following array.
                    self.channelsDataArray.append(desiredValuesDict)
                    
                    
                    // Reload the tableview.
                    self.tblVideos.reloadData()
                    
                    // Load the next channel data (if exist).
                    ++self.channelIndex
                    if self.channelIndex < self.desiredChannelsArray.count {
                        self.getChannelDetails(useChannelIDParam)
                    }
                    else {
                        self.viewWait.hidden = true
                    }
                } catch {
                    print(error)
                }
                
            } else {
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel details: \(error)")
            }
        })
    }

    
    func getVideosForChannelAtIndex(index: Int!) {
        // Get the selected channel's playlistID value from the channelsDataArray array and use it for fetching the proper video playlst.
        let playlistID = channelsDataArray[index]["playlistID"] as! String
        
        // Form the request URL string.
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(playlistID)&key=\(apiKey)"
        
        // Create a NSURL object based on the above string.
        let targetURL = NSURL(string: urlString)
        
        // Fetch the playlist from Google.
        performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            if HTTPStatusCode == 200 && error == nil {
                do {
                    // Convert the JSON data into a dictionary.
                    let resultsDict = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! Dictionary<NSObject, AnyObject>
                    
                    // Get all playlist items ("items" array).
                    let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                    
                    // Use a loop to go through all video items.
                    for var i=0; i<items.count; ++i {
                        let playlistSnippetDict = (items[i] as Dictionary<NSObject, AnyObject>)["snippet"] as! Dictionary<NSObject, AnyObject>
                        
                        // Initialize a new dictionary and store the data of interest.
                        var desiredPlaylistItemDataDict = Dictionary<NSObject, AnyObject>()
                        
                        desiredPlaylistItemDataDict["title"] = playlistSnippetDict["title"]
                        desiredPlaylistItemDataDict["thumbnail"] = ((playlistSnippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
                        desiredPlaylistItemDataDict["videoID"] = (playlistSnippetDict["resourceId"] as! Dictionary<NSObject, AnyObject>)["videoId"]
                        
                        // Append the desiredPlaylistItemDataDict dictionary to the videos array.
                        self.videosArray.append(desiredPlaylistItemDataDict)
                        
                        // Reload the tableview.
                        self.tblVideos.reloadData()
                    }
                } catch {
                    print(error)
                }
            }
            else {
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel videos: \(error)")
            }
            
            // Hide the activity indicator.
            self.viewWait.hidden = true
        })
    }
}

