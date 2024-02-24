function user_is_admin \
    --description 'Tests whether USER is a member of the admin group.'
    if is_mac
        test "user is a member of the group" = (dsmemberutil checkmembership -U $USER -G "admin")
    else if is_linux
        groups | grep -q adm
    end
end
