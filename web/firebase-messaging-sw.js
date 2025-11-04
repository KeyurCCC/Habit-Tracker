// web/firebase-messaging-sw.js
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCCySfNMrnrDFOSJYMcACZGOJaBWB9Y8cI",
  authDomain: "flutter-pwa-d76bd.firebaseapp.com",
  projectId: "flutter-pwa-d76bd",
  storageBucket: "flutter-pwa-d76bd.firebasestorage.app",
  messagingSenderId: "967335157253",
  appId: "1:967335157253:web:fa70278f0162966890c66c",
});

// Retrieve messaging instance
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log("Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
