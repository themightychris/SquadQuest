import {
    createAnonSupabaseClient,
    createServiceRoleSupabaseClient,
    getSupabaseUser,
  } from "../_shared/supabase.ts";
  import {
    assertPost,
    getRequiredJsonParameters,
    HttpError,
  } from "../_shared/http.ts";

  Deno.serve(async (request) => {
    try {
      // process request
      assertPost(request);
      const { requestee } = await getRequiredJsonParameters(request, [
        "requestee",
      ]);

      // connect to Supabase
      const serviceRoleSupabase = createServiceRoleSupabaseClient();
      const anonSupabase = createAnonSupabaseClient(request);

      // get requesting user
      const requesterUser = await getSupabaseUser(anonSupabase, request);
      if (!requesterUser) {
        throw new HttpError(
          "Authorized user not found",
          403,
          "authorized-user-not-found",
        );
      }

      // get requestee user
      const { data: requesteeUser, error: requesteeError } =
        await serviceRoleSupabase.from(
          "profiles",
        )
          .select("*")
          .eq("id", requestee)
          .maybeSingle();
      if (requesteeError) throw requesteeError;
      if (!requesteeUser) {
        throw new HttpError("Requestee not found", 404, "requestee-not-found");
      }

      // check that no link exists already in either direction
      const { count: existingFriendsCount, error: existingFriendsError } =
        await serviceRoleSupabase.from(
          "friends",
        )
          .select("*", { count: "exact", head: true })
          .in("requester", [requesterUser.id, requesteeUser.id])
          .in("requestee", [requesterUser.id, requesteeUser.id]);
      if (existingFriendsError) throw existingFriendsError;
      if (existingFriendsCount! > 0) {
        throw new HttpError(
          "A matching friend connection already exists",
          400,
          "friend-exists",
        );
      }

      // insert friend request
      const { data: newFriendRequest, error: insertError } =
        await serviceRoleSupabase.from("friends")
          .insert({
            requester: requesterUser.id,
            requestee: requesteeUser.id,
            status: "requested",
          })
          .select()
          .single();
      if (insertError) throw insertError;

      // return new friend request
      return new Response(
        JSON.stringify(newFriendRequest),
        {
          headers: { "Content-Type": "application/json" },
          status: 200,
        },
      );
    } catch (error) {
      if (error instanceof HttpError) {
        return new Response(
          JSON.stringify({ message: error.message, error_id: error.errorId }),
          {
            headers: { "Content-Type": "application/json" },
            status: error.code,
          },
        );
      }

      return new Response(
        JSON.stringify({
          message: String(error?.message ?? error),
          error_id: error.errorId,
        }),
        {
          headers: { "Content-Type": "application/json" },
          status: 500,
        },
      );
    }
  });
