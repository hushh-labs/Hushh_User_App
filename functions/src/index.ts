import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';

// Global options and initialization
setGlobalOptions({ region: 'us-central1' });
try {
  initializeApp();
} catch {}

const db = getFirestore();
const messaging = getMessaging();

interface OrderItem {
  productId?: string;
  productName?: string;
  quantity?: number;
}

export const notifyAgentOnOrderCreate = onDocumentCreated('orders/{orderId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const data = snap.data() as any;
  if (!data) return;

  const status = String(data.status || '').toLowerCase();
  if (status !== 'confirmed') return;

  const agentId: string | undefined = data.agentId || data.agentID || data.agent_id;
  if (!agentId) return;

  const agentDoc = await db.collection('Hushhagents').doc(agentId).get();
  if (!agentDoc.exists) return;

  const agentData = agentDoc.data() || {};
  const fcmToken: string | undefined = agentData.fcm_token || agentData.fcmToken || agentData.token;
  if (!fcmToken) return;

  const fullName: string = data.deliveryAddress?.fullName || data.fullName || 'Customer';
  const items: OrderItem[] = Array.isArray(data.items) ? data.items : [];
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
  } catch (err) {
    console.error('FCM send failed', err);
    await snap.ref.update({ agentNotifyError: String(err) });
  }
});
