function renew_certificates --description='Renews certificates on servers.'
    # Only run on server
    if test (hostname) != mini
        return 1
    end

    # Only admins can update certs
    if not user_is_admin
        return 2
    end

    sudo certbot renew
end
