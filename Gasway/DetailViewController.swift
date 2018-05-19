//
//  DetailViewController.swift
//  Gasway
//
//  Created by Alan Sánchez Vázquez on 3/12/18.
//  Copyright © 2018 alansnchz. All rights reserved.
//

import UIKit
import Font_Awesome_Swift
import MapKit
import Firebase

class DetailViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var regularPriceField: UITextField!
    @IBOutlet weak var premiumPriceField: UITextField!
    @IBOutlet weak var dieselPriceField: UITextField!
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var commentsScrollView: UIScrollView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var reactionProgress: UIProgressView!
    @IBOutlet weak var commentTextView: UITextView!
    
    var station: Station!
    
    var db: Firestore!
    
    var uid: String?
    var commentId: String?
    var reactionId: String?

    var scrollViewHeight: CGFloat = 0
    
    var isCommentValid: Bool = false
    let formatter = DateFormatter()
    
    enum GasType: String {
        case regular = "regular"
        case premium = "premium"
        case diesel = "diesel"
    }
    
    enum Reaction {
        case dislike
        case like
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTextView.delegate = self
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        commentsScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // [START Firebase setup]
        db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        // [END Firebase setup]
        
        uid = Auth.auth().currentUser?.uid
        
        // [START Keyboard setup]
        registerForKeyboardNotifications()
        self.hideKeyboardWhenTappedAround()
        // [END Keyboard setup]
        
        // [START Like buttons setup]
        likeButton.layer.cornerRadius = 0.5 * likeButton.bounds.size.width
        likeButton.clipsToBounds = true
        dislikeButton.layer.cornerRadius = 0.5 * dislikeButton.bounds.size.width
        dislikeButton.clipsToBounds = true
        likeButton.setImage(UIImage.init(
                icon: .FAThumbsUp,
                size: CGSize(width: 96,
                             height: 96),
                textColor: .blue,
                backgroundColor: .clear),
            for: .normal)
        dislikeButton.setImage(UIImage.init(
            icon: .FAThumbsDown,
            size: CGSize(width: 96,
                         height: 96),
            textColor: .red,
            backgroundColor: .clear),
            for: .normal)
        // [END Like buttons setup]
        
        // [START Navigation bar setup]
        let rb = UIBarButtonItem(title: "Ir", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.openInMaps))
        self.navigationItem.rightBarButtonItem = rb
        // [END Navigation bar setup]
        
        // [START Station setup]
        guard let s = station else {
            return
        }
        
        self.title = s.creId
        titleLabel.text = s.name
        subTitleLabel.text = s.address
        for price in station.prices {
            switch price.type {
                case GasType.regular.rawValue:
                    regularPriceField.isHidden = false
                    regularPriceField.text = "$" + price.price
                    break
                case GasType.premium.rawValue:
                    premiumPriceField.isHidden = false
                    premiumPriceField.text = "$" + price.price
                    break
                case GasType.diesel.rawValue:
                    dieselPriceField.isHidden = false
                    dieselPriceField.text = "$" + price.price
                    break
                default:
                    regularPriceField.isHidden = false
                    regularPriceField.text = "$" + price.price
                    break
            }
        }
        // [END Station setup]
        
        getStation()
        getComments()
        getReactions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = ""
        textView.textColor = UIColor.black
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Escriba un comentario."
            textView.textColor = UIColor.darkGray
            isCommentValid = false
        } else {
            isCommentValid = true
        }
    }
    
    @IBAction func didReaction(_ sender: Any) {
        switch sender as! UIButton {
            case likeButton:
                createReaction(type: Reaction.like.hashValue)
                break
            case dislikeButton:
                createReaction(type: Reaction.dislike.hashValue)
                break
            default:
                createReaction(type: Reaction.like.hashValue)
                break
        }
    }
    
    @objc func openInMaps() {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude))
        let mapItem = MKMapItem(placemark: placemark)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    @IBAction func didComment(_ sender: Any) {
        if isCommentValid {
            createComment()
        }
    }
    
    func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.view.window?.frame.origin.y = -1 * keyboardHeight!
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.view.window?.frame.origin.y = 0
            self.view.layoutIfNeeded()
        })
    }
    
    func getStation() {
        let stationRef = db.collection("stations").document(station.placeId)
        stationRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting stations: \(error)")
            } else {
                if document!.exists {
                    //Document exists do nothing...
                } else {
                    self.createStation()
                }
            }
        }
    }
    
    func createStation() {
        db.collection("stations").document(station.placeId).setData([
            "address_street": station.address,
            "brand": station.brand,
            "category": station.category,
            "cre_id": station.creId,
            "lat": station.latitude,
            "lng": station.longitude,
            "name": station.name
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    
    func getComments() {
       
            deleteCommentsFromView()
        db.collection("stations").document(station.placeId).collection("comments").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                for (i, document) in querySnapshot!.documents.enumerated() {
                    
                    if document.data()["user"] as? String == self.uid! {
                        self.commentId = document.documentID
                        self.commentTextView.text = document.data()["comment"] as? String
                    }
                    
                    let field = self.createField(
                        comment: (document.data()["comment"] as? String)!,
                        position: Double(i))
                    _ = self.createLabel(
                        date: document.data()["date"] as! Timestamp,
                        commentAnchor: field.topAnchor,
                        i: i,
                        j: (querySnapshot!.documents.count - 1))
                    self.scrollViewHeight += 80
                }
                self.commentsScrollView.contentSize.height = self.scrollViewHeight
            }
        }
    }
    
    func getReactions() {
        db.collection("stations").document(station.placeId).collection("reactions").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var likes: Float = 0.0
                var dislikes: Float = 0.0
                for document in querySnapshot!.documents {
                    if document.data()["user"] as? String == self.uid! {
                        self.reactionId = document.documentID
                    }
                    if document.data()["type"] as? Int == 0 {
                        dislikes += 1.0
                    } else {
                        likes += 1.0
                    }
                }
                let likesProgress = (likes + dislikes) > 0 ? Float(likes / (likes + dislikes)) : 0.0
                self.reactionProgress.setProgress(likesProgress, animated: true)
                
                if likesProgress > 0.5 {
                    self.reactionProgress.progressTintColor = UIColor.blue
                } else {
                    self.reactionProgress.progressTintColor = UIColor.red
                }
            }
        }
    }
    
    func createReaction(type: Int) {
        var newReactionRef: DocumentReference
        if reactionId != nil {
            newReactionRef = db.collection("stations").document(station.placeId).collection("reactions").document(reactionId!)
        } else {
            newReactionRef = db.collection("stations").document(station.placeId).collection("reactions").document()
        }
        newReactionRef.setData([
            "type": type,
            "date": NSDate(),
            "user": uid!
        ])  { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
                self.getReactions()
            }
        }
    }
        
    func createComment() {
        var newCommentRef: DocumentReference
        if commentId != nil {
            newCommentRef = db.collection("stations").document(station.placeId).collection("comments").document(commentId!)
        } else {
            newCommentRef = db.collection("stations").document(station.placeId).collection("comments").document()
        }
        newCommentRef.setData([
            "comment": commentTextView.text,
            "date": NSDate(),
            "user": uid!
        ])  { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
                self.getComments()
            }
        }
    }
    
    func deleteCommentsFromView() {
        for view in commentsScrollView.subviews {
            view.removeFromSuperview()
        }
    }
    
    func createField(comment: String, position: Double) -> UITextField {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.text = comment
        field.isEnabled = false
        field.translatesAutoresizingMaskIntoConstraints = false
        
        self.commentsScrollView.addSubview(field)
        
        // [START field constraints]
        field.widthAnchor.constraint(equalToConstant: 350.0).isActive = true
        field.leadingAnchor.constraint(equalTo: self.commentsScrollView.leadingAnchor, constant: 16.0).isActive = true
        field.trailingAnchor.constraint(equalTo: self.commentsScrollView.trailingAnchor, constant: 16.0).isActive = true
        field.topAnchor.constraint(equalTo: self.commentsScrollView.topAnchor, constant: CGFloat(( position + 1.0 ) * 52.0 )).isActive = true
        // [END field constraints]
        
        return field
    }
    
    func createLabel(date: Timestamp, commentAnchor: NSLayoutYAxisAnchor, i: Int, j: Int) -> UITextField {
        let label = UITextField()
        let ts: Timestamp = date
        let dt = self.formatter.string(from: ts.dateValue())
        label.text = dt
        label.translatesAutoresizingMaskIntoConstraints = false
        
        self.commentsScrollView.addSubview(label)
        
        // [START field constraints]
        label.leadingAnchor.constraint(equalTo: self.commentsScrollView.leadingAnchor, constant: 48.0).isActive = true
        label.trailingAnchor.constraint(equalTo: self.commentsScrollView.trailingAnchor, constant: 16.0).isActive = true
        label.topAnchor.constraint(equalTo: commentAnchor, constant: 32.0).isActive = true
        // [END field constraints]
        
        if i == j {
            label.bottomAnchor.constraint(equalTo:
                self.commentsScrollView.bottomAnchor, constant: 2.0).isActive = true
        }
        
        return label
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
