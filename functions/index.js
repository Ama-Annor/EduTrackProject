// Firebase Cloud Functions for EduTrack
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Require axios for external API calls and cors for API endpoints
const axios = require("axios");
const cors = require("cors")({origin: true});

// Helper function to fetch a motivational quote
async function fetchMotivationalQuote() {
  try {
    const response = await axios.get("https://zenquotes.io/api/random");
    const quote = `"${response.data[0].q}" - ${response.data[0].a}`;
    return quote;
  } catch (error) {
    console.error("Error fetching quote:", error);
    // Fallback quotes
    const fallbackQuotes = [
      "\"The secret of getting ahead is getting started.\" - Mark Twain",
      "\"It always seems impossible until it's done.\" - Nelson Mandela",
      "\"Don't watch the clock; do what it does. Keep going.\" - Sam Levenson",
      "\"Believe you can and you're halfway there.\" - Theodore Roosevelt",
      "\"Success is not final, failure is not fatal: It is the courage to continue that counts.\" - Winston Churchill",
    ];
    return fallbackQuotes[Math.floor(Math.random() * fallbackQuotes.length)];
  }
}

// Helper function to get a study tip
function getStudyTip() {
  const studyTips = [
    "Try the Pomodoro Technique: 25 minutes of focused study followed by a 5-minute break.",
    "Review your notes within 24 hours of taking them to improve retention.",
    "Create mind maps to connect related concepts and improve understanding.",
    "Explain concepts out loud as if teaching someone else to enhance your understanding.",
    "Study in short, regular sessions rather than one long cramming session.",
    "Stay hydrated! Drinking water improves brain function and concentration.",
    "Get enough sleep. Your brain processes and stores information during sleep.",
    "Change study locations occasionally to improve memory and concentration.",
    "Use active recall instead of just rereading material. Test yourself frequently.",
    "Take short breaks to walk or stretch to maintain focus and energy.",
  ];

  return studyTips[Math.floor(Math.random() * studyTips.length)];
}

// API endpoint to manually send a motivational quote (for testing)
exports.send_motivational_quote = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).send({error: "Method Not Allowed"});
    }

    const userEmail = req.body.email;

    if (!userEmail) {
      return res.status(400).send({error: "Email is required"});
    }

    try {
      // Get the user document
      const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(userEmail)
          .get();

      if (!userDoc.exists) {
        return res.status(404).send({error: "User not found"});
      }

      const userData = userDoc.data();

      if (!userData.fcmToken) {
        return res.status(400).send({error: "User has no FCM token"});
      }

      // Get a motivational quote
      const quote = await fetchMotivationalQuote();

      // Send the notification
      await admin.messaging().send({
        token: userData.fcmToken,
        notification: {
          title: "Motivational Quote",
          body: quote,
        },
        data: {
          type: "motivational_quote",
        },
      });

      return res.status(200).send({success: true, message: "Notification sent successfully"});
    } catch (error) {
      console.error("Error sending notification:", error);
      return res.status(500).send({error: error.message});
    }
  });
});
/*
// Scheduled task to send motivational quotes to all users who opted in
exports.sendDailyMotivationalQuotes = functions.scheduler
  .schedule('0 8 * * *', {
    timeZone: 'UTC'
  })
  .onRun(async (context) => {
      try {
      // Get all users who opted in for motivational quotes
        const usersSnapshot = await admin
            .firestore()
            .collection("users")
            .where("motivationalQuoteReminders", "==", true)
            .get();

        if (usersSnapshot.empty) {
          console.log("No users have opted in for motivational quotes");
          return null;
        }

        // Get a motivational quote
        const quote = await fetchMotivationalQuote();

        // Send to all users who opted in
        const promises = [];

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();

          if (userData.fcmToken) {
            promises.push(
                admin.messaging().send({
                  token: userData.fcmToken,
                  notification: {
                    title: "Daily Motivation",
                    body: quote,
                  },
                  data: {
                    type: "motivational_quote",
                  },
                })
                    .catch((error) => {
                      console.error("Error sending to token:", error);
                      // If the error is related to the token, update the user document
                      if (error.code === "messaging/invalid-registration-token" ||
                  error.code === "messaging/registration-token-not-registered") {
                        return admin
                            .firestore()
                            .collection("users")
                            .doc(doc.id)
                            .update({fcmToken: admin.firestore.FieldValue.delete()});
                      }
                      return null;
                    }),
            );
          }
        });

        await Promise.all(promises);
        console.log(`Sent motivational quotes to ${promises.length} users`);

        return null;
      } catch (error) {
        console.error("Error sending motivational quotes:", error);
        return null;
      }
    });
*/
/*
// Scheduled task to send study tips to all users who opted in
exports.sendDailyStudyTips = functions.scheduler
  .schedule('0 16 * * *', {
    timeZone: 'UTC'
  })
  .onRun(async (context) => {
      try {
      // Get all users who opted in for study tips
        const usersSnapshot = await admin
            .firestore()
            .collection("users")
            .where("studyTipReminders", "==", true)
            .get();

        if (usersSnapshot.empty) {
          console.log("No users have opted in for study tips");
          return null;
        }

        // Get a study tip
        const tip = getStudyTip();

        // Send to all users who opted in
        const promises = [];

        usersSnapshot.forEach((doc) => {
          const userData = doc.data();

          if (userData.fcmToken) {
            promises.push(
                admin.messaging().send({
                  token: userData.fcmToken,
                  notification: {
                    title: "Study Tip",
                    body: tip,
                  },
                  data: {
                    type: "study_tip",
                  },
                })
                    .catch((error) => {
                      console.error("Error sending to token:", error);
                      // If the error is related to the token, update the user document
                      if (error.code === "messaging/invalid-registration-token" ||
                  error.code === "messaging/registration-token-not-registered") {
                        return admin
                            .firestore()
                            .collection("users")
                            .doc(doc.id)
                            .update({fcmToken: admin.firestore.FieldValue.delete()});
                      }
                      return null;
                    }),
            );
          }
        });

        await Promise.all(promises);
        console.log(`Sent study tips to ${promises.length} users`);

        return null;
      } catch (error) {
        console.error("Error sending study tips:", error);
        return null;
      }
    });
*/
/*
// Scheduled task to send deadline reminders
exports.sendDeadlineReminders = functions.scheduler
  .schedule('0 9 * * *', {
    timeZone: 'UTC'
  })
  .onRun(async (context) => {
      try {
      // Calculate tomorrow's date range
        const today = new Date();
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(0, 0, 0, 0);

        const tomorrowEnd = new Date(tomorrow);
        tomorrowEnd.setHours(23, 59, 59, 999);

        // Convert to Firestore timestamps
        const tomorrowStart = admin.firestore.Timestamp.fromDate(tomorrow);
        const tomorrowEndTS = admin.firestore.Timestamp.fromDate(tomorrowEnd);

        // Get all deadlines due tomorrow
        const deadlinesSnapshot = await admin
            .firestore()
            .collection("deadlines")
            .where("dueDate", ">=", tomorrowStart)
            .where("dueDate", "<=", tomorrowEndTS)
            .get();

        if (deadlinesSnapshot.empty) {
          console.log("No deadlines due tomorrow");
          return null;
        }

        // Group deadlines by user email
        const deadlinesByUser = {};

        deadlinesSnapshot.forEach((doc) => {
          const deadline = doc.data();
          const userEmail = deadline.email;

          if (!deadlinesByUser[userEmail]) {
            deadlinesByUser[userEmail] = [];
          }

          deadlinesByUser[userEmail].push(deadline);
        });

        // Send notifications to each user about their deadlines
        const promises = [];

        for (const userEmail of Object.keys(deadlinesByUser)) {
        // Get the user's FCM token
          const userDoc = await admin
              .firestore()
              .collection("users")
              .doc(userEmail)
              .get();

          if (!userDoc.exists) {
            console.log(`User document not found for email: ${userEmail}`);
            continue;
          }

          const userData = userDoc.data();
          const fcmToken = userData.fcmToken;

          if (!fcmToken) {
            console.log(`No FCM token found for user: ${userEmail}`);
            continue;
          }

          const deadlines = deadlinesByUser[userEmail];

          // Create a notification message
          let notificationTitle;
          let notificationBody;

          if (deadlines.length === 1) {
          // Single deadline
            const deadline = deadlines[0];
            notificationTitle = "Deadline Reminder";
            notificationBody = `"${deadline.subject}" is due tomorrow at ${deadline.dueTime}`;
          } else {
          // Multiple deadlines
            notificationTitle = "Deadline Reminders";
            notificationBody = `You have ${deadlines.length} deadlines due tomorrow`;
          }

          // Send the notification
          promises.push(
              admin.messaging().send({
                token: fcmToken,
                notification: {
                  title: notificationTitle,
                  body: notificationBody,
                },
                data: {
                  type: "deadline_reminder",
                  count: String(deadlines.length),
                },
              })
                  .catch((error) => {
                    console.error(`Error sending to token for ${userEmail}:`, error);
                    // Handle token errors
                    if (error.code === "messaging/invalid-registration-token" ||
                error.code === "messaging/registration-token-not-registered") {
                      return admin
                          .firestore()
                          .collection("users")
                          .doc(userEmail)
                          .update({fcmToken: admin.firestore.FieldValue.delete()});
                    }
                    return null;
                  }),
          );
        }

        await Promise.all(promises);
        console.log(`Sent deadline reminders to ${promises.length} users`);

        return null;
      } catch (error) {
        console.error("Error sending deadline reminders:", error);
        return null;
      }
    });
*/
// API endpoint to get study statistics
exports.getStudyStats = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== "GET") {
      return res.status(405).send({error: "Method Not Allowed"});
    }

    const userEmail = req.query.email;

    if (!userEmail) {
      return res.status(400).send({error: "Email parameter is required"});
    }

    try {
      // Get study hours
      const studyHoursSnapshot = await admin
          .firestore()
          .collection("studyHours")
          .where("email", "==", userEmail)
          .get();

      // Get study timer records
      const studyTimersSnapshot = await admin
          .firestore()
          .collection("studyTimers")
          .where("userID", "==", userEmail)
          .get();

      // Calculate statistics
      const courseTotals = {};
      let totalHours = 0;

      // Process manual study hours
      studyHoursSnapshot.forEach((doc) => {
        const data = doc.data();
        const course = data.course.toLowerCase();
        const hours = parseFloat(data.hoursLogged) || 0;

        if (!courseTotals[course]) {
          courseTotals[course] = 0;
        }

        courseTotals[course] += hours;
        totalHours += hours;
      });

      // Process timer records
      studyTimersSnapshot.forEach((doc) => {
        const data = doc.data();
        const course = data.course.toLowerCase();

        // Calculate hours from timer (assuming format is HH:MM)
        const startParts = data.startTime.split(":");
        const endParts = data.endTime.split(":");

        const startMinutes = parseInt(startParts[0]) * 60 + parseInt(startParts[1]);
        const endMinutes = parseInt(endParts[0]) * 60 + parseInt(endParts[1]);

        // Handle day overflow (if end time is on the next day)
        let minutesDiff = endMinutes - startMinutes;
        if (minutesDiff < 0) {
          minutesDiff += 24 * 60; // Add a full day in minutes
        }

        const hours = minutesDiff / 60;

        if (!courseTotals[course]) {
          courseTotals[course] = 0;
        }

        courseTotals[course] += hours;
        totalHours += hours;
      });

      // Format the response
      const courseBreakdown = Object.entries(courseTotals).map(([course, hours]) => {
        const percentage = totalHours > 0 ? (hours / totalHours) * 100 : 0;

        return {
          course,
          hours: parseFloat(hours.toFixed(2)),
          percentage: parseFloat(percentage.toFixed(1)),
        };
      });

      // Sort by most hours first
      courseBreakdown.sort((a, b) => b.hours - a.hours);

      const stats = {
        totalHours: parseFloat(totalHours.toFixed(2)),
        courseBreakdown,
      };

      return res.status(200).send(stats);
    } catch (error) {
      console.error("Error fetching study stats:", error);
      return res.status(500).send({error: error.message});
    }
  });
});

// API endpoint to get all deadlines for a user
exports.getDeadlines = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== "GET") {
      return res.status(405).send({error: "Method Not Allowed"});
    }

    const userEmail = req.query.email;

    if (!userEmail) {
      return res.status(400).send({error: "Email parameter is required"});
    }

    try {
      const deadlinesSnapshot = await admin
          .firestore()
          .collection("deadlines")
          .where("email", "==", userEmail)
          .orderBy("dueDate", "asc")
          .get();

      const deadlines = [];
      deadlinesSnapshot.forEach((doc) => {
        deadlines.push(doc.data());
      });

      return res.status(200).send(deadlines);
    } catch (error) {
      console.error("Error fetching deadlines:", error);
      return res.status(500).send({error: error.message});
    }
  });
});

// API endpoint to get all schedules for a user
exports.getSchedules = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== "GET") {
      return res.status(405).send({error: "Method Not Allowed"});
    }

    const userEmail = req.query.email;

    if (!userEmail) {
      return res.status(400).send({error: "Email parameter is required"});
    }

    try {
      const schedulesSnapshot = await admin
          .firestore()
          .collection("schedules")
          .where("email", "==", userEmail)
          .orderBy("date", "asc")
          .get();

      const schedules = [];
      schedulesSnapshot.forEach((doc) => {
        schedules.push(doc.data());
      });

      return res.status(200).send(schedules);
    } catch (error) {
      console.error("Error fetching schedules:", error);
      return res.status(500).send({error: error.message});
    }
  });
});
