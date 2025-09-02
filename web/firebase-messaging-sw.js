importScripts("https://www.gstatic.com/firebasejs/9.19.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.19.1/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyAYhT3Xf3dTfjnv7ZKGFJKxeSHkpJJ4raU",
    authDomain: "el-massa-consult.firebaseapp.com",
    projectId: "el-massa-consult",
    storageBucket: "el-massa-consult.firebasestorage.app",
    messagingSenderId: "165315212535",
    appId: "1:165315212535:web:ae5298a962011d1fad4ff2",
    measurementId: "G-7R3Z6CE6DM"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(async (payload) => {
  console.log('Received background message:', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    click_action: payload.notification.click_action,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});