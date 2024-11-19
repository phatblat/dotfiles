function ddd \
    --description='Delete Derived Data'

    if test -z $DERIVED_DATA
        error "DERIVED_DATA is not set"
        return 1
    end

    if test -d $DERIVED_DATA
        echo "Deleting derived data directory $DERIVED_DATA"
        rm -rf $DERIVED_DATA
    else
        error "Derived data directory does not exist"
    end
end
