const functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp();

exports.createNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate((snap, context) => {
      var db = admin.firestore();

      let usersRef = db.collection('users');
      let shopsRef = db.collection('shops');

      let notificationData = snap.data();

      let receiver_uid = notificationData.receiver_uid;
      let title = notificationData.title;
      let body = notificationData.body;
      let sender_type = notificationData.sender_type;

      if (sender_type == "users"){
        let t_query = shopsRef.where('uid', '==', receiver_uid).get()
            .then(snap => {
              if (snap.empty){
                return;
              }
              snap.forEach(async (e) => {
                console.log("Sending...");
                let token = e.data().token;
                console.log(token);
                const payload = {'notification': {'title': title, 'body': body}};
                await admin.messaging().sendToDevice(token, payload);
                console.log("sent");
              });
            }).catch(err => {console.log('Error getting token', err)});
      } else {
        let t_query = usersRef.where('uid', '==', receiver_uid).get()
            .then(snap => {
              if (snap.empty){
                return;
              }
              snap.forEach(async (e) => {
                console.log("Sending...");
                let token = e.data().token;
                console.log(token);
                const payload = {'notification': {'title': title, 'body': body}};
                await admin.messaging().sendToDevice(token, payload);
                console.log("sent");
              });
            }).catch(err => {console.log('Error getting token', err)});
      }
     return "done";
    });
