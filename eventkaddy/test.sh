# $("find . -name '*.rb' -mmin -60")

while true
do
        if [[ -n $(find . -name '*.rb' -mmin -1) ]]
        then
            rake test
            # echo "files modified in last minute"
            # echo "no files modified in last minute"
        fi
        sleep 15
done

