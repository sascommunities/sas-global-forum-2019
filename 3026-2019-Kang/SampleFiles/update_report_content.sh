
# change the dataset name for report.
old_data_table=\"PRDSALE\"
new_data_table=\"PRDSALEEDU\"
sed -i "s/$old_data_table/$new_data_table/g" original_reportcontent.txt

#change the report title.
old_report_name="\"Overall Sales Report\""
new_report_name="\"Education Division Sales Report\""
sed -i "s/$old_report_name/$new_report_name/g" original_reportcontent.txt


