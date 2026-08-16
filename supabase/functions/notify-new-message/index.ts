// Supabase Edge Function: notify-new-message
//
// Nasłuchuje inserty w tabeli `messages` (webhook z Database Webhooks —
// skonfiguruj w Supabase Dashboard: Database > Webhooks > INSERT na `messages`
// wskazujący na ten endpoint). Pobiera odbiorcę wiadomości, jego tokeny FCM
// z `user_devices` i wysyła push przez Google FCM HTTP v1 API.
//
// Wymagane zmienne środowiskowe (supabase secrets set):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//   FCM_PROJECT_ID            — projectId z Firebase
//   FCM_SERVICE_ACCOUNT_JSON  — pełny JSON konta serwisowego Firebase (jako string)

import { createClient } from 'jsr:@supabase/supabase-js@2';

interface MessageRow {
  id: string;
  chat_id: string;
  sender_id: string;
  text: string;
}

interface WebhookPayload {
  type: 'INSERT';
  table: string;
  record: MessageRow;
}

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

async function getGoogleAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')!);

  const now = Math.floor(Date.now() / 1000);
  const jwtHeader = { alg: 'RS256', typ: 'JWT' };
  const jwtClaim = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');

  const unsigned = `${encode(jwtHeader)}.${encode(jwtClaim)}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );

  const signedJwt = `${unsigned}.${
    btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/=+$/, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
  }`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: signedJwt,
    }),
  });

  const tokenJson = await tokenResponse.json();
  return tokenJson.access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function sendFcmPush(token: string, title: string, body: string) {
  const projectId = Deno.env.get('FCM_PROJECT_ID')!;
  const accessToken = await getGoogleAccessToken();

  await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
        },
      }),
    },
  );
}

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json();

  if (payload.type !== 'INSERT' || payload.table !== 'messages') {
    return new Response('ignored', { status: 200 });
  }

  const message = payload.record;

  const { data: chat } = await supabaseAdmin
    .from('chats')
    .select('buyer_id, seller_id')
    .eq('id', message.chat_id)
    .single();

  if (!chat) return new Response('chat not found', { status: 404 });

  const recipientId =
    chat.buyer_id === message.sender_id ? chat.seller_id : chat.buyer_id;

  const { data: sender } = await supabaseAdmin
    .from('profiles')
    .select('username')
    .eq('id', message.sender_id)
    .single();

  const { data: devices } = await supabaseAdmin
    .from('user_devices')
    .select('fcm_token')
    .eq('user_id', recipientId);

  if (!devices || devices.length === 0) {
    return new Response('no devices', { status: 200 });
  }

  await Promise.all(
    devices.map((d) =>
      sendFcmPush(d.fcm_token, sender?.username ?? 'Nowa wiadomość', message.text)
    ),
  );

  return new Response('ok', { status: 200 });
});
