module ReportsHelper
  NO_DATA = 'No data available for this date range'
  def branches(branch_id=0)
    arr2 = Branch.where(:is_active=>true).all
    arr2 = arr2.map{|x| [x.name, x.id]}
    arr = [ ['-Select-', nil], ['All', 0] ].concat(arr2)
    options_for_select(arr, branch_id)
  end
  
  def table_helper(data, cells)
    html = %{<table border="1" cellpadding="0" cellspacing="0" class="summary ui-collection" id="-report">}
    html << %{<thead><tr>}
    cells.each do | e |
      html << %{<th class="-#{e[0]}" scope="col">#{e[1]}</th>}
    end
    html << %{</tr></thead>}
    rows = 0
    data.each do | t |
      rows += 1
      html <<  %{<tr class=#{cycle("ui-state","ui-state-alternate")} >}
      cells.each do | e |
        v = eval(e[2])
        v = '-' if v.blank?
        html<< %{<td class="#{e[0]}">#{h v}</td>}
      end
      html<<%{</tr>}
    end 
    html << %{</table>}

    html << NO_DATA if rows == 0
    html
  end 

  def csv_helper(data, cells)
    titles = []
    cells.each do | e |
      titles << e[1]
    end
    ndata = [data]
    values = []
    content = FasterCSV.generate(:col_sep => "\t") do |csv|
      if ndata.empty?
        csv << titles
        next
      end
      ndata.each do |dat|
        csv << titles
        total_fee = 0
        total_amount = 0
        dat.each do |t|
          values = []
          cells.each do | e |
            values << value_to_string(eval(e[2]))
          end
          csv << values 
        end
      end
    end
    bom = "\377\376" # Byte Order Mark
    content = bom + Iconv.conv("utf-16le", "utf-8", content)
    # send_data content, :filename => filename
  end
  def branch_report_title
    title = [
          'Branch Name',
          'Date',
          'Number of Callers', # Stat.new.number_of_calls
          'Average time listening',
          'Average total call time', # Stat.new.call_times[:average]
          'Number of Messages Left', # Stat.new.messages[:total]
          'Country'
          ]
  end

  # branch is a open struct
  def branch_report_row(branch)
    c=branch
    values = {}
    values['Charity Name']=c.name
    values['Date']=Time.now_to_s(:db)
    values['Number of Callers']=(c.number_of_callers) rescue ""
    values['Average time listening'] =(c.average_time_listening) rescue ""
    values['Average total call time']=c.average_total_call_time
    values['Number of Messages Left']= c.numbe_of_messages_left
    values['Country']=c.country
    values         
  end
  
  def branch_csv_helper(branches)
    content = FasterCSV.generate(:col_sep => "\t") do |csv|
        csv << branch_report_title
        branches.each do |c|
          row = branch_report_row(c)
          row_data = []
          branch_report_title.each do | key |
            if row.has_key?(key)
              row_data << row[key]
            else
              raise("#{key} not found!")
            end
          end
          csv << row_data
        end
    end
    bom = "\377\376" # Byte Order Mark
    content = bom + Iconv.conv("utf-16le", "utf-8", content)
    # send_data content, :filename => filename
  end

end