//
//  ViewController.swift
//  Polling
//
//  Created by DCC User on 12/8/15.
//  Copyright © 2015 HACS378N. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate,
MCSessionDelegate {
    let serviceType = "polling"
    
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    var session : MCSession!
    var peerID : MCPeerID!
    
    var foundPeers = [MCPeerID]()

    @IBOutlet var chatView: UITextView!
    @IBOutlet var messageField: UITextField!
    @IBOutlet weak var numTriggeredDevices: UILabel!
    
    var triggered = false
    var invitationHandler: ((Bool, MCSession)->Void)!
    var triggeredDevices: [MCPeerID]!
    
    let ARE_YOU_TRIGGERED = "I am triggered. Are you guys?\n"
    let NO_MORE_TRIGGERED = "I am not triggered anymore.\n"
    let NOT_TRIGGERED = "No, I am not triggered.\n"
    let AM_TRIGGERED = "Yes, I am triggered too.\n"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        self.browser.delegate = self
        
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.advertiser.delegate = self
        
        // Start advertising and browsing
        self.advertiser.startAdvertisingPeer()
        self.browser.startBrowsingForPeers()
    }
    
    
    // Called when trigger occurs
    @IBAction func triggerEvent(sender: UIButton) {
        triggered = !triggered
        
        if (!triggered && triggeredDevices != nil){
            triggeredDevices.removeAtIndex(triggeredDevices.indexOf(self.peerID)!)
        }
        
        if (self.triggeredDevices == nil && triggered){
            self.triggeredDevices = [self.peerID]
        }
        else if (!self.triggeredDevices.contains(self.peerID) && triggered){
            self.triggeredDevices.append(self.peerID)
        }

        self.numTriggeredDevices.text = String(self.triggeredDevices.count)
        if (triggered){
            sendMessageToPeers(self.ARE_YOU_TRIGGERED, peers: self.session.connectedPeers)
        }
        else {
            sendMessageToPeers(self.NO_MORE_TRIGGERED, peers: self.session.connectedPeers)
        }
    }

    
    func sendMessageToPeers(msg: NSString, peers: [MCPeerID]){
        do {
            try self.session.sendData(msg.dataUsingEncoding(NSUTF8StringEncoding)!, toPeers: peers, withMode: MCSessionSendDataMode.Unreliable)
        } catch {
            self.chatView.text = self.chatView.text + "Failed to send message!\n"
        }
        updateChat(msg as String, fromPeer: self.peerID)
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
    
    // Got invite
    func advertiser(advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: NSData?,
        invitationHandler: (Bool,
        MCSession) -> Void){
        self.invitationHandler = invitationHandler
        self.invitationHandler(true, self.session)
    }
    
    // Advertiser error
    func advertiser(advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: NSError){
            
    }
    
    // Found peer
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 10)
        dispatch_async(dispatch_get_main_queue()) {
            self.chatView.text = self.chatView.text + "\(peerID.displayName) connected\nAll peers: " +
                String(self.session.connectedPeers) + "\n"
        }
    }
    
    // Lost peer
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        for (index, aPeer) in foundPeers.enumerate(){
            if aPeer == peerID {
                foundPeers.removeAtIndex(index)
                break
            }
        }
    }
    
    // Browser error
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print(error.localizedDescription)
    }
    
    func session(session: MCSession, didReceiveData data: NSData,
        fromPeer peerID: MCPeerID)  {
            // Called when a peer sends an NSData to us
        
            // This needs to run on the main queue
            dispatch_async(dispatch_get_main_queue()) {
                
                let msg = NSString(data: data, encoding: NSUTF8StringEncoding)
                
                self.updateChat(msg as! String, fromPeer: peerID)
                
                if (msg == self.NO_MORE_TRIGGERED){
                    if (self.triggeredDevices.contains(peerID)){
                        self.triggeredDevices.removeAtIndex(self.triggeredDevices.indexOf(peerID)!)
                    }
                }
                
                else if (msg == self.ARE_YOU_TRIGGERED){
                    if (self.triggered){
                        self.sendMessageToPeers(self.AM_TRIGGERED, peers: [peerID])
                    }
                    else {
                        self.sendMessageToPeers(self.NOT_TRIGGERED, peers: [peerID])
                    }
                    if (self.triggeredDevices != nil && !self.triggeredDevices.contains(peerID)){
                        self.triggeredDevices.append(peerID)
                    }
                    if (self.triggeredDevices == nil){
                        self.triggeredDevices = [peerID]
                    }
                }
                    
                else if (msg == self.AM_TRIGGERED){
                    if (!self.triggeredDevices.contains(peerID)){
                        self.triggeredDevices.append(peerID)
                    }
                }
                
                else if (msg == self.NOT_TRIGGERED){
                    if (self.triggeredDevices.contains(peerID)){
                        self.triggeredDevices.removeAtIndex(self.triggeredDevices.indexOf(peerID)!)
                    }
                }
                if (self.triggeredDevices != nil){
                    self.numTriggeredDevices.text = String(self.triggeredDevices.count)
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
            switch state {
            case MCSessionState.Connected: break
                //self.chatView.text = self.chatView.text + "\(peerID.displayName) connected\n"
            case MCSessionState.Connecting: break
                //self.chatView.text = self.chatView.text + "\(peerID.displayName) connecting\n"
            case MCSessionState.NotConnected: break
                //self.chatView.text = self.chatView.text + "\(peerID.displayName) not connected\n"
            }
    }
}