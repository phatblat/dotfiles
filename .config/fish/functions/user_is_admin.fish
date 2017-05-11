# Tests whether USER is a member of the admin group.
function user_is_admin
    test "user is a member of the group" = (dsmemberutil checkmembership -U $USER -G "admin")
end
