import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function respond(
  status: number,
  body: Record<string, unknown>,
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return respond(405, {
      error: 'Only POST requests are supported.',
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return respond(500, {
      error: 'Admin function is not configured.',
    });
  }

  const authorization = request.headers.get('Authorization');
  const token = authorization?.replace(/^Bearer\s+/i, '');

  if (!token) {
    return respond(401, {
      error: 'A signed-in administrator is required.',
    });
  }

  const authClient = createClient(supabaseUrl, anonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const { data: authData, error: authError } =
    await authClient.auth.getUser(token);

  if (authError || !authData.user) {
    return respond(401, {
      error: 'Your session is invalid or expired.',
    });
  }

  const { data: adminProfile, error: adminError } =
    await serviceClient
      .from('profiles')
      .select('role')
      .eq('id', authData.user.id)
      .maybeSingle();

  if (adminError) {
    console.error('Admin profile lookup failed:', adminError.message);
    return respond(500, {
      error: 'Could not verify administrator access.',
    });
  }

  if (adminProfile?.role !== 'admin') {
    return respond(403, {
      error: 'Administrator access is required.',
    });
  }

  let payload: Record<string, unknown>;

  try {
    const body: unknown = await request.json();

    if (
      body === null ||
      typeof body !== 'object' ||
      Array.isArray(body)
    ) {
      return respond(400, {
        error: 'Request body must be a JSON object.',
      });
    }

    payload = body as Record<string, unknown>;
  } catch {
    return respond(400, {
      error: 'Request body must be valid JSON.',
    });
  }

  const action = payload.action;
  const targetUserId = payload.targetUserId;

  if (typeof action !== 'string') {
    return respond(400, { error: 'An action is required.' });
  }

  if (action === 'invite-user') {
    const email = payload.email;
    const displayName = payload.displayName;

    if (
      typeof email !== 'string' ||
      email.trim().length > 254 ||
      !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) ||
      typeof displayName !== 'string' ||
      displayName.trim().length < 2 ||
      displayName.trim().length > 120
    ) {
      return respond(400, {
        error: 'A valid email and full name are required.',
      });
    }

    const { data, error } =
      await serviceClient.auth.admin.inviteUserByEmail(
        email.trim(),
        { data: { full_name: displayName.trim() } },
      );

    if (error) {
      return respond(400, { error: error.message });
    }

    return respond(200, {
      ok: true,
      action,
      userId: data.user?.id,
    });
  }

  if (
    typeof targetUserId !== 'string' ||
    !uuidPattern.test(targetUserId)
  ) {
    return respond(400, { error: 'A valid target user ID is required.' });
  }

  if (targetUserId === authData.user.id) {
    return respond(400, {
      error: 'Administrators cannot change their own account.',
    });
  }

  const { data: targetProfile, error: targetProfileError } =
    await serviceClient
      .from('profiles')
      .select('role')
      .eq('id', targetUserId)
      .maybeSingle();

  if (targetProfileError) {
    console.error(
      'Target profile lookup failed:',
      targetProfileError.message,
    );
    return respond(500, {
      error: 'Could not verify the target account.',
    });
  }

  if (!targetProfile) {
    return respond(404, {
      error: 'The target account profile was not found.',
    });
  }

  if (action === 'set-role') {
    const role = payload.role;

    if (role !== 'student' && role !== 'admin') {
      return respond(400, {
        error: 'Role must be student or admin.',
      });
    }

    if (role === 'student') {
      const { count, error: countError } = await serviceClient
        .from('profiles')
        .select('id', { count: 'exact', head: true })
        .eq('role', 'admin');

      if (countError) {
        console.error(
          'Administrator count failed:',
          countError.message,
        );
        return respond(500, {
          error: 'Could not verify administrator accounts.',
        });
      }

      if (targetProfile.role === 'admin' && (count ?? 0) <= 1) {
        return respond(409, {
          error: 'The final administrator cannot be demoted.',
        });
      }
    }

    const { data: updatedProfile, error } = await serviceClient
      .from('profiles')
      .update({ role })
      .eq('id', targetUserId)
      .select('id')
      .maybeSingle();

    if (error) {
      return respond(400, { error: error.message });
    }

    if (!updatedProfile) {
      return respond(404, {
        error: 'The target account profile was not found.',
      });
    }

    return respond(200, {
      ok: true,
      action,
      targetUserId,
      role,
    });
  }

  if (action === 'suspend' || action === 'restore') {
    if (action === 'suspend' && targetProfile.role === 'admin') {
      return respond(409, {
        error: 'Revoke administrator access before suspending this account.',
      });
    }

    const { error: authUpdateError } =
      await serviceClient.auth.admin.updateUserById(
        targetUserId,
        {
          ban_duration:
            action === 'suspend' ? '876000h' : 'none',
        },
      );

    if (authUpdateError) {
      return respond(400, { error: authUpdateError.message });
    }

    const { error: profileUpdateError } = await serviceClient
      .from('profiles')
      .update({ is_suspended: action === 'suspend' })
      .eq('id', targetUserId);

    if (profileUpdateError) {
      console.error(
        'Account status sync failed:',
        profileUpdateError.message,
      );
      return respond(500, {
        error: 'Auth status changed, but profile status sync failed.',
      });
    }

    return respond(200, {
      ok: true,
      action,
      targetUserId,
    });
  }

  if (action === 'delete-user') {
    if (targetProfile.role === 'admin') {
      const { count, error: countError } = await serviceClient
        .from('profiles')
        .select('id', { count: 'exact', head: true })
        .eq('role', 'admin');

      if (countError) {
        return respond(500, {
          error: 'Could not verify administrator accounts.',
        });
      }

      if ((count ?? 0) <= 1) {
        return respond(409, {
          error: 'The final administrator cannot be deleted.',
        });
      }
    }

    const { error } =
      await serviceClient.auth.admin.deleteUser(targetUserId);

    if (error) {
      return respond(400, { error: error.message });
    }

    return respond(200, {
      ok: true,
      action,
      targetUserId,
    });
  }

  return respond(400, {
    error: 'Unsupported admin action.',
  });
});