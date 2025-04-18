import FirebaseCore
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    let db: Firestore
    
    private init() {
        db = Firestore.firestore()
    }
}
