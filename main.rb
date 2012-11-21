# File to scrape data from spareroom.co.uk
# This is full of dirty hacks as this just needs to work and do no more

require 'rubygems'
require 'net/http'
require 'json'

@allInfo = [];
@minPrice = 10000;
@maxPrice = 0;

class Array
  def shuffle
    sort_by { rand }
  end

  def shuffle!
    self.replace shuffle
  end
end

class Result
def single 
	@single
end
def single=(single)
	@single = single
end
def double 
	@double
end
def double=(double)
	@double = double
end
def postcode
	@postcode
end
def postcode=(postcode)
	@postcode = postcode
end
def lat 
@lat
  end
  def lat=(lat)
    @lat = lat
  end
  def lng
    @lng
  end
  def lng=(lng)
    @lng = lng
  end

end

class LocInfo
def lat 
@lat
  end
  def lat=(lat)
    @lat = lat
  end
  def lng
    @lng
  end
  def lng=(lng)
    @lng = lng
  end
end


def downloadArea(code)
	puts "download area " + code;
	Net::HTTP.start("www.spareroom.co.uk") { |http|
		resp = http.get("/flatshare/where_to_live_wizard.pl?action=piechart&postcode_id="+code+"&to=area_info_popup")
		open("data/"+code+".html", "wb") { |file|
			file.write(resp.body)
		}
	}

end

def downloadLocation(postcode)
	puts "download location " + postcode;
	Net::HTTP.start("maps.googleapis.com") { |http|
		resp = http.get("/maps/api/geocode/json?address="+postcode+",+United+Kingdom&sensor=false")
		open("data/"+postcode+".json", "wb") { |file|
			file.write(resp.body)
		}
	}
end

def extractData(code)
	file = File.new("data/"+code+".html", "r");
	#contents = file.read.force_encoding("UTF-8")
	contents = file.read();
	result = Result.new
	result.single = "-1"
	result.double = "-1"
	
	title = contents.scan(/<title>([^<>]*)<\/title>/imu).flatten[0]
	result.postcode = title.scan(/\(([A-Z][A-Z0-9]*)\)/imu).flatten[0]
	if result.postcode==nil
		return
	end
	if contents.length > 5000
		names = contents.scan(/<dt>([^<>]*)<\/dt>/imu).flatten
		values = contents.scan(/<dd>([^<>]*)<\/dd>/imu).flatten
		for i in (0..names.length-1)
			val = values[i].scan(/[\d*]/imu).flatten.join
			if names[i].eql? "Double Room"
				result.double = val
			else
				result.single = val
			end
		end
	end
	if !result.single.eql? "-1" or !result.double.eql? "-1"
		if !File.exists?("data/"+result.postcode+".json")
			downloadLocation(result.postcode)
			sleep(rand(5));
		end
		file = File.new("data/"+result.postcode+".json", "r");
		locData = JSON.parse(file.read)
		locInfo = extractLocInfo(locData["results"])
		result.lat = locInfo.lat
		result.lng = locInfo.lng
		if result.double.length == 0
			result.double = "0";
		end
		json = '{"t":"'+title+'","c":'+code+',"pc":"'+result.postcode+'","single":'+result.single+',"double":'+result.double+',"lat":'+locInfo.lat.to_s+',"lng":'+locInfo.lng.to_s+'}';
		@allInfo.push(json);
		valTemp = Integer(result.single);
		if valTemp > 0
			@minPrice = [@minPrice,valTemp].min;
			@maxPrice = [@maxPrice,valTemp].max;
		end
		#puts @minPrice;
		#puts @maxPrice;
	end
end

def extractLocInfo(locData)
	ret = LocInfo.new
	
	ret.lat = 0.0
	ret.lng = 0.0
	ret.lat = locData[0]["geometry"]["location"]["lat"]
	ret.lng = locData[0]["geometry"]["location"]["lng"]
	
	
	return ret
end

def readAreaInfo()
	items = []
	for i in (1..2905)
		items.push(i);
	end
	items.shuffle!
	

	for i in items
		st = i.to_s
		
		if !File.exists?("data/"+st+".html")
			downloadArea(st);
			#sleep(rand(3))
		end
		extractData(st);
	end

end

def dumpResults
		file = File.new("result.json", "wb");
		ret = 'var data = {"min":'+@minPrice.to_s(10)+',"max":'+@maxPrice.to_s(10)+ ',"items":[';
		for s in @allInfo
			ret+= s + ","
		end
		ret = ret[0,ret.length-1]
		ret+=']};';
		
		file.write(ret)
end

readAreaInfo()
dumpResults()

