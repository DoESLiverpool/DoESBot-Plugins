require 'rubygems'
require 'net/http'
require 'hpricot'

class TrainTimesPlugin < Plugin
  def help(plugin, topic="")
    "traintimes <from> <to> => show times of next train from station <from> to station <to>"
  end

  def cal_path
    @bot.config["cal.path"]
  end

  def traintimes(m, params)
    unless params.has_key?(:from)
      # We haven't got a from, so assume it's from liverpool
      params[:from] = "lvc"
    end

    if params.has_key?(:from) && params.has_key?(:to)
      # Download the results page
      m.reply "Getting train times from http://m.traintimes.org.uk/"+params[:from]+"/"+params[:to]
      resp = Net::HTTP.get_response("m.traintimes.org.uk", "/"+params[:from]+"/"+params[:to])
      # Parse the results
      doc = Hpricot(resp.body)
      # Output the stations to confirm we got the right results
      h = (doc/"h2")[0]
      m.reply h.children[0].to_plain_text+" ["+h.children[1].children[1].to_plain_text+"]"+(h.children[2].to_plain_text.gsub(/[\n\t\302\240]/, ' ').squeeze(" "))+"["+h.children[3].children[1].to_plain_text+"]"
      # Iterate over the time rows
      (doc/"ul[2]/li").each do |t|
        if t.to_s.match(/note-noshadow.png/)
	  # Very basic test to see if there's a note (late, problem, etc.)
	  r = t.children[0].to_plain_text.sub(/\342\200\223/, "->").gsub(/[\n\t\302\240]/, ' ').squeeze(" ")+" NOTE: "+t.children[1].children[1].to_plain_text+t.children[3].children[0].to_plain_text
	  if t.children[3].children[0].to_plain_text.match(/direct/)
	    # It's a direct train
	    r = r.chomp("; ")+")"
	  else
	    # There are changes
	    r = r+t.children[3].children[1].to_plain_text.sub(/\s\[.*\]/, "")+")"
	  end
          m.reply r
        else
          r = t.children[0].to_plain_text.sub(/\342\200\223/, "->").gsub(/[\n\t\302\240]/, ' ').squeeze(" ")+" "+t.children[2].to_plain_text
	  if t.children[2].to_plain_text.match(/direct/)
	    # It's a direct train
	    r = r.chomp("; ")+")"
	  else
	    # There are changes
	    r = r+t.children[2].children[1].to_plain_text.sub(/\s\[.*\]/, "")+")"
	  end
          m.reply r
        end
      end
    else
      m.reply "Need to know where you want train times for.  Usage is 'traintimes [from_station] to_station' (if from_station is omitted, Liverpool Central is assumed)"
    end
  end
end
plugin = TrainTimesPlugin.new
plugin.map 'traintimes :from :to', :requirements => {:from => /^\w+$/, :to => /^\w+$/}
plugin.map 'traintimes :to', :requirements => {:to => /^\w+$/ }
plugin.map 'traintimes'
