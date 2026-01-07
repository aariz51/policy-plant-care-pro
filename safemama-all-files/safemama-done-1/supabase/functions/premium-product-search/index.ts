// supabase/functions/premium-product-search/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'; // Or your preferred Deno std version

console.log('[premium-product-search Edge Function] Booting up...');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*', // Restrict in production
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS', // We'll use POST from Flutter
};

// IMPORTANT: Set this in your Supabase project's Edge Function environment variables/secrets
const NODE_JS_BACKEND_URL = Deno.env.get('NODE_JS_BACKEND_URL_FOR_SAFEMAMA'); // e.g., http://your-ip:3001 or your deployed backend URL

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Verify JWT from Authorization header (recommended for protecting the function)
  // Supabase automatically verifies if --no-verify-jwt is NOT used during deploy
  // For this example, let's assume JWT verification is handled or we'll add it later if needed.

  if (!NODE_JS_BACKEND_URL) {
    console.error('NODE_JS_BACKEND_URL_FOR_SAFEMAMA environment variable not set.');
    return new Response(JSON.stringify({ error: 'Server configuration error.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  try {
    const requestBody = await req.json();
    const productNameQuery = requestBody.query; // From Flutter: 'query' field
    const userContext = requestBody.userContext;  // From Flutter: 'userContext' field

    if (!productNameQuery || typeof productNameQuery !== 'string' || productNameQuery.trim() === '') {
      return new Response(JSON.stringify({ error: 'Invalid or missing search query.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    console.log(`[EdgeFunction] Forwarding to Node.js: Product="${productNameQuery}", Context=${JSON.stringify(userContext)}`);

    const nodeJsResponse = await fetch(`${NODE_JS_BACKEND_URL}/api/analyze-textual-product`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // Optional: Forward the user's Supabase JWT if your Node.js backend needs to verify the user
        // 'Authorization': req.headers.get('Authorization') || '',
      },
      body: JSON.stringify({ productName: productNameQuery, userContext: userContext || {} }),
    });

    const nodeJsResponseData = await nodeJsResponse.json();

    if (!nodeJsResponse.ok) {
      console.error(`[EdgeFunction] Error from Node.js backend (${nodeJsResponse.status}):`, nodeJsResponseData);
      // Relay the error structure if possible, or a generic one
      const errorToRelay = nodeJsResponseData?.error || nodeJsResponseData?.message || 'Error from analysis service';
      return new Response(JSON.stringify({ error: errorToRelay }),
        { status: nodeJsResponse.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // The Node.js backend returns a single analysis object.
    // The Flutter ApiService.premiumProductSearch expects a LIST.
    // So, wrap the successful result in a list.
    // If nodeJsResponseData indicates an analysis failure (e.g. AI couldn't identify),
    // it should ideally return an empty list or a specific error structure.
    // For now, assume if nodeJsResponse.ok, nodeJsResponseData is the good analysis.
    return new Response(JSON.stringify([nodeJsResponseData]), { // Wrap in a list
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (err) {
    console.error('[EdgeFunction] Unhandled error:', err);
    // It's good to check if err has a message property
    const errorMessage = err instanceof Error ? err.message : 'Internal Server Error in Edge Function';
    return new Response(JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});