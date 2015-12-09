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
    @IBOutlet weak var numTriggeredDevices: UILabel!
    
    var triggered = false
    var triggeredDevices: [MCPeerID]!
    
    let ARE_YOU_TRIGGERED = "I am triggered. Are you guys?"
    let NOT_TRIGGERED = "No, I am not triggered."
    let AM_TRIGGERED = "Yes, I am triggered too."
    
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
        
        // Start advertising
        self.assistant.start()
    }
    
    // Called when trigger occurs
    @IBAction func triggerEvent(sender: UIButton) {
        if (!self.triggeredDevices.contains(self.peerID)){
            self.triggeredDevices.append(self.peerID)
        }
        self.numTriggeredDevices.text = String(self.triggeredDevices.count)
        sendMessageToPeers(self.ARE_YOU_TRIGGERED, peers: self.session.connectedPeers)
    }
    
    func sendMessageToPeers(msg: NSString, peers: [MCPeerID]){
        do {
            try self.session.sendData(msg.dataUsingEncoding(NSUTF8StringEncoding)!, toPeers: peers, withMode: MCSessionSendDataMode.Reliable)
        } catch {
            self.chatView.text = self.chatView.text + "Failed to send message!"
        }
        updateChat(msg as String, fromPeer: self.peerID)
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
            self.chatView.text = self.chatView.text + "Failed to send message!"
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
                
                if (msg == self.ARE_YOU_TRIGGERED){
                    if (self.triggered){
                        self.sendMessageToPeers(self.AM_TRIGGERED, peers: [peerID])
                        if (!self.triggeredDevices.contains(peerID)){
                            self.triggeredDevices.append(peerID)
                        }
                    }
                    else {
                        self.sendMessageToPeers(self.NOT_TRIGGERED, peers: [peerID])
                    }
                }
                    
                else if (msg == self.AM_TRIGGERED){
                    if (!self.triggeredDevices.contains(peerID)){
                        self.triggeredDevices.append(peerID)
                    }
                }
                
                else if (msg == self.NOT_TRIGGERED){
                    self.triggered = false;
                    if (self.triggeredDevices.contains(peerID)){
                        self.triggeredDevices.removeAtIndex(self.triggeredDevices.indexOf(peerID)!)
                    }
                    if (self.triggeredDevices.contains(self.peerID)){
                        self.triggeredDevices.removeAtIndex(self.triggeredDevices.indexOf(self.peerID)!)
                    }
                }
                self.numTriggeredDevices.text = String(self.triggeredDevices.count)
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
            self.session.connectPeer(peerID, withNearbyConnectionData: ("Let's connect." as NSString).dataUsingEncoding(NSUTF8StringEncoding)!)
            switch state {
            case MCSessionState.Connected:
                self.chatView.text = self.chatView.text + "\(peerID.displayName) connected"
            case MCSessionState.Connecting:
                self.chatView.text = self.chatView.text + "\(peerID.displayName) connecting"
            case MCSessionState.NotConnected:
                self.chatView.text = self.chatView.text + "\(peerID.displayName) not connected"
            }
    }
}