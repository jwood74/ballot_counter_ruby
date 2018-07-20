class Ballot
	def initialize(raw_ballots, header, ballot_type, candidates_to_elect)
		@votes = import_votes(raw_ballots, header, ballot_type)
		@total_votes = @votes.count
		@formal_votes = count_formal
		@current_total = @formal_votes.to_f
		@current_exhaust = 0.0
		@candidates_to_elect = candidates_to_elect.to_i
		@candidates = import_candidates(raw_ballots,header)
		@cur_candidate_count = @candidates.count
		@candidates_elected = 0
		@has_winner = false
		@quota = calculate_quota
		@ballot_type = ballot_type
	end

	attr_reader :votes, :total_votes, :formal_votes, :candidates, :has_winner, :first_pref_results, :current_total, :cur_candidate_count, :quota, :candidates_elected, :candidates_to_elect, :current_exhaust, :ballot_type
	attr_writer :has_winner, :current_total, :cur_candidate_count, :quota, :candidates_elected, :current_exhaust

	def calculate_quota
		return (@current_total / (@candidates_to_elect + 1).to_f)
	end

	def import_votes(raw_ballots, header, ballot_type)
		votes = []
		raw_ballots.each_with_index do |b, i|
			if header && i == 0
				next
			end
			votes << BallotPaper.new(b, ballot_type)
		end
		return(votes)
	end

	def count_formal
		formal = 0
		@votes.each do |b|
			if b.is_formal
				formal += 1
			end
		end
		return formal
	end

	def import_candidates(raw_ballots,header)
		candidates = []
		can_count = 0
		@votes.each do |b|
			if b.order.count > can_count
				can_count = b.order.count
			end
		end

		if header
			raw_ballots[0].each_with_index do |c, i|
				candidates[i] = Candidate.new(i, @votes, @formal_votes,c)
			end

		else
			can_count.times do |c|
				candidates[c] = Candidate.new(c,@votes, @formal_votes)
			end
		end
		
		return candidates
	end

end

class BallotPaper
	def initialize(aballot, ballot_type)
		@order = aballot
		@is_formal = check_formal(ballot_type)
		@cur_candidate = find_cur_candidate
		@is_exhaust = false
		@value = 1.0
	end

	attr_reader :order, :is_formal, :cur_candidate, :is_exhaust, :value
	attr_writer :cur_candidate, :is_exhaust, :value

	def check_formal(ballot_type)

		if ballot_type == 'opv' || ballot_type == 'pr'
			if @order.include?("1") && @order.count("1") == 1
				return true
			end
		elsif ballot_type == 'cpv'
			@order.count.times do |t|
				if not @order.count((t + 1).to_s) == 1
					# puts "missing #{t + 1}"
					return false
				end
			end
			return true
		end
		return false
	end

	def find_cur_candidate
		if @is_formal
			cur_candidate = @order.index("1")
		else
			cur_candidate = nil
		end
		return cur_candidate
	end
end

class Candidate
	def initialize(pos,votes,form_votes, cname = nil)
		@position = pos + 1
		@name = set_name(pos,cname)
		@first_pref = count_first_pref(pos,votes)
		@first_pref_pc = @first_pref / form_votes.to_f * 100
		@cur_votes = @first_pref.to_f
		@excluded = false
		@elected = false
		@elected_order = 0
	end

	attr_reader :position, :first_pref, :first_pref_pc, :cur_votes, :excluded, :name, :elected_order, :elected
	attr_writer :cur_votes, :excluded, :elected_order, :elected

	def set_name(pos,cname)
		if cname
			return cname
		else
			return pos
		end
	end

	def count_first_pref(pos,votes)
		can_fp = 0
		votes.each do |v|
			if v.order[pos] == "1" && v.is_formal
				can_fp += 1
			end
		end
		return can_fp
	end

end