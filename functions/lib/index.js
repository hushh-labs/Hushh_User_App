"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyAgentOnOrderCreate = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const firestore_2 = require("firebase-functions/v2/firestore");
const v2_1 = require("firebase-functions/v2");
// Global options and initialization
(0, v2_1.setGlobalOptions)({ region: 'us-central1' });
try {
    (0, app_1.initializeApp)();
}
catch { }
const db = (0, firestore_1.getFirestore)();
const messaging = (0, messaging_1.getMessaging)();
exports.notifyAgentOnOrderCreate = (0, firestore_2.onDocumentCreated)('orders/{orderId}', async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    if (!data)
        return;
    const status = String(data.status || '').toLowerCase();
    if (status !== 'confirmed')
        return;
    const agentId = data.agentId || data.agentID || data.agent_id;
    if (!agentId)
        return;
    const agentDoc = await db.collection('Hushhagents').doc(agentId).get();
    if (!agentDoc.exists)
        return;
    const agentData = agentDoc.data() || {};
    const fcmToken = agentData.fcm_token || agentData.fcmToken || agentData.token;
    if (!fcmToken)
        return;
    const fullName = data.deliveryAddress?.fullName || data.fullName || 'Customer';
    const items = Array.isArray(data.items) ? data.items : [];
    const firstTitle = items[0]?.productName || (items.length > 0 ? 'Product' : '');
    const extraCount = items.length > 1 ? ` +${items.length - 1} more` : '';
    const productSummary = firstTitle ? `${firstTitle}${extraCount}` : 'New order items';
    const title = 'New order placed';
    const body = `${fullName} placed an order: ${productSummary}. Please proceed to fulfillment.`;
    try {
        await messaging.send({
            token: fcmToken,
            notification: { title, body },
            data: {
                orderId: String(event.params.orderId ?? ''),
                agentId: String(agentId),
                status: String(data.status || 'confirmed'),
                totalAmount: String(data.totalAmount ?? ''),
                currency: String(data.currency ?? ''),
                userId: String(data.userId ?? ''),
            },
            android: { priority: 'high' },
            apns: { headers: { 'apns-priority': '10' }, payload: { aps: { sound: 'default' } } },
        });
        await snap.ref.update({ agentNotifiedAt: new Date() });
    }
    catch (err) {
        console.error('FCM send failed', err);
        await snap.ref.update({ agentNotifyError: String(err) });
    }
});
