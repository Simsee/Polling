//
//  ViewController.swift
//  Polling
//
//  Created by DCC User on 12/8/15.
//  Copyright © 2015 HACS378N. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate,
MCSessionDelegate {
    
    let serviceType = "polling"
    
    var browser : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID : MCPeerID!
    
    @IBOutlet var chatView: UITextView!
    @IBOutlet var messageField: UITextField!
    
    var triggered = false
    var triggeredDevices: [MCPeerID]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        // create the browser viewcontroller with a unique service name
        self.browser = MCBrowserViewController(serviceType:serviceType,
            session:self.session)
        
        self.browser.delegate = self;
        
        self.assistant = MCAdvertiserAssistant(serviceType:serviceType,
            discoveryInfo:nil, session:self.session)
    }
    
    // Called when trigger occurs
    @IBAction func triggerEvent(sender: UIButton) {
        self.assistant.stop()
        // Start advertising
        self.assistant.start()
        sendMessageToPeers("YO! Did something happen?", peers: self.session.connectedPeers)
    }
    
    func sendMessageToPeers(msg: NSString, peers: [MCPeerID]){
        do {
            try self.session.sendData(msg.dataUsingEncoding(NSUTF8StringEncoding)!, toPeers: peers, withMode: MCSessionSendDataMode.Reliable)
        } catch {
            self.chatView.text = self.chatView.text + "Could not send message to peer(s)"
        }
    }
    
    @IBAction func sendChat(sender: UIButton, msg : NSString) {
        // Bundle up the text in the message field, and send it off to all
        // connected peers
        
        let msg = self.messageField.text!.dataUsingEncoding(NSUTF8StringEncoding,
            allowLossyConversion: false)
        
        do {
             try self.session.sendData(msg!, toPeers: self.session.connectedPeers,
                withMode: MCSessionSendDataMode.Unreliable)
        } catch {
            self.chatView.text = self.chatView.text + "Error sending chat message (are you connected to any peers?)\n"
        }
        
        self.updateChat(self.messageField.text!, fromPeer: self.peerID)
        
        self.messageField.text = ""
    }
    
    func updateChat(text : String, fromPeer peerID: MCPeerID) {
        // Appends some text to the chat view
        
        // If this peer ID is the local device's peer ID, then show the name
        // as "Me"
        var name : String
        
        switch peerID {
        case self.peerID:
            name = "Me"
        default:
            name = peerID.displayName
        }
        
        // Add the name to the message and display it
        let message = "\(name): \(text)\n"
        self.chatView.text = self.chatView.text + message
        
    }
    
    @IBAction func showBrowser(sender: UIButton) {
        // Show the browser view controller
        self.presentViewController(self.browser, animated: true, completion: nil)
    }
    
    func browserViewControllerDidFinish(
        browserViewController: MCBrowserViewController)  {
            // Called when the browser view controller is dismissed (ie the Done
            // button was tapped)
            
            self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(
        browserViewController: MCBrowserViewController)  {
            // Called when the browser view controller is cancelled
            
            self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func session(session: MCSession, didReceiveData data: NSData,
        fromPeer peerID: MCPeerID)  {
            // Called when a peer sends an NSData to us
        
            // This needs to run on the main queue
            dispatch_async(dispatch_get_main_queue()) {
                
                let msg = NSString(data: data, encoding: NSUTF8StringEncoding)
                
                self.updateChat(msg as! String, fromPeer: peerID)
                
                if (msg == "YO! Did something happen?"){
                    if (self.triggered){
                        self.sendMessageToPeers("YO! Something did happen.", peers: [peerID])
                    }
                    else {
                        self.sendMessageToPeers("YO! Nothing happened.", peers: [peerID])
                    }
                }
                    
                else if (msg == "YO! Something did happen."){
                    if (!self.triggeredDevices.contains(peerID)){
                        self.triggeredDevices.append(peerID)
                    }
                }
                
                else if (msg == "YO! Nothing happened."){
                    self.triggered = false;
                    self.assistant.stop()
                    if (self.triggeredDevices.contains(peerID)){
                        self.triggeredDevices.removeAtIndex(self.triggeredDevices.indexOf(peerID)!)
                    }
                }

            }
    }
    
    func session(session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        withProgress progress: NSProgress){
    
    }
    
    func session(session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        atURL localURL: NSURL,
        withError error: NSError?){
            
    }
    
    func session(session: MCSession,
        didReceiveStream stream: NSInputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID){
            
    }
    
    func session(session: MCSession,
        peer peerID: MCPeerID,
        didChangeState state: MCSessionState){
            self.session.connectPeer(peerID, withNearbyConnectionData: ("YO! Let's connect." as NSString).dataUsingEncoding(NSUTF8StringEncoding)!)
            switch state {
            case MCSessionState.Connected:
                print("Connected: \(peerID.displayName)")
                self.chatView.text = self.chatView.text + "Connected: \(peerID.displayName)"
            case MCSessionState.Connecting:
                print("Connecting: \(peerID.displayName)")
                self.chatView.text = self.chatView.text + "Connecting: \(peerID.displayName)"
            case MCSessionState.NotConnected:
                print("Not Connected: \(peerID.displayName)")
                self.chatView.text = self.chatView.text + "Not Connected: \(peerID.displayName)"
            }
    }
}