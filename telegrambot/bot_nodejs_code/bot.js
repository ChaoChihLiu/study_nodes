const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();

// Your Telegram Bot Token
const TELEGRAM_TOKEN = '7108XXXX07:AAEc-nCXXXXXXXXXXXVqhLqkXIWmFcc';
const TELEGRAM_API_URL = `https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`;

// Parse incoming JSON messages
app.use(bodyParser.json());

// The webhook endpoint that Telegram will call
app.post('/webhook', (req, res) => {
    // The incoming message from Telegram
    const message = req.body.message;

    // Log the message
    console.log('Received message:', message);

    // Check if the message contains text
    if (message && message.text) {
        // Example: Send a reply back to the user
        const chatId = message.chat.id;
        const replyText = `You said: ${message.text}`;

        // Send a message back to the user using the Telegram API
        axios.post(TELEGRAM_API_URL, {
            chat_id: chatId,
            text: replyText
        })
        .then(response => {
            console.log('Message sent:', response.data);
        })
        .catch(error => {
            console.error('Error sending message:', error);
        });
    }

    // Respond with 200 OK to acknowledge receipt of the message
    res.send('OK');
});

// Start the server on port 3000 (or any available port)
app.listen(446, () => {
    console.log('Server is running on port 446');
});
