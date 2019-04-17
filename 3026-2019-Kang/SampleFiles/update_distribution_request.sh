sed -i "s/<username>/new_username/g" distribution_request.txt
sed -i "s/<distribution_name>/distribution for education disvision/g" distribution_request.txt
sed -i "s/<reportid>/$new_report_id/g" distribution_request.txt  
sed -i "s/<distribution_subject>/Sales report for education division/g" distribution_request.txt
sed -i "s/<distribution_body>/Dear colleagues, this is the sales report for education division. /g" distribution_request.txt