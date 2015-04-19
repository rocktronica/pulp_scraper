#!/bin/bash

{
    blog_url="http://pulpcovers.com/tag/scifi"
    page_limit=10

    function download_images() {
        mkdir -p images
        while read url; do
            filename=$(echo $url | grep -oE '[^/]*.jpg')

            echo $filename
            if [ ! -f images/$filename ]; then
                curl -# $url > images/$filename
                sleep 1
            fi
        done;
    }

    function parse_cache_page_for_images() {
        mkdir -p cache
        cat cache/$1.html | \
            grep -oE "href=[^>]*" | \
            grep -oE "[^'\"]*.jpg"
    }

    function download_page_to_cache() {
        if [ ! -f cache/$1.html ]; then
            curl -L "$blog_url/page/$1/" > \
                cache/$1.html
            sleep 1
        fi
    }

    function run() {
        going=true
        page_number=1

        function stop_going_if_page_out_of_images() {
            images_count=$(parse_cache_page_for_images $page_number | wc -l)
            expected_max_images_per_page=10
            if (( $images_count <= $expected_max_images_per_page )); then
                going=false
            fi
        }

        function stop_if_page_limit_reached() {
            if (( $page_number > $page_limit )); then
                going=false
            fi
        }

        while $going; do
            echo "Page $page_number"

            download_page_to_cache $page_number
            stop_going_if_page_out_of_images

            parse_cache_page_for_images $page_number | download_images

            let page_number=$page_number+1
            stop_if_page_limit_reached

            echo '\n------------------------\n'
        done;

    }

    run
}
