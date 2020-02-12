function email_url \
        --description='Determines an appropriate contact for a given url' \
        --argument-names url

    set -l user ben
    set -l work_domain kp.org
    set -l default $user@octop.ad

    if test -z "$url"
        echo $default
        return
    end

    if string match --quiet --entire -- $work_domain $url
        echo $user.d.chatelain@$work_domain
    else
        echo $default
    end
end
