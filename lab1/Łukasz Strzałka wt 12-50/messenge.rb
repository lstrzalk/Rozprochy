class Messenge
	def initialize(id, nickname)
		@id = id
		@nickname = nickname
	end
	def encode(req, flag)
		send = ""
		messenge = {:id => @id, :nickname => @nickname, :body => req, :flag => flag}
		messenge.map { |key, value|  send = send + key.to_s + ' : ' + value.to_s + ' ; '}
		return send
	end
	def decode(res)
		messenge = res.split(/\W;\W/);
		rec = {}
		messenge.each do |x|
			y = x.split(/\W:\W/)
			rec[y[0].to_sym] = y[1]
		end
		return rec
	end
	def setID(id)
		@id = id
	end
	def setNickname(nickname)
		@nickname = nickname
	end
	def getHeaderSize
		return @id.size + @nickname.size + 3 + 9 + 5 + 5 +1
	end
end