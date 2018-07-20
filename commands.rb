def print_first_preference(ballot)
	display_candidates = ballot.candidates.sort_by { |x| x.cur_votes }.reverse

	display_candidates.each do |c|
		puts "	Candidate #{c.name} received #{c.first_pref} first preference votes (or #{c.first_pref_pc.round(2)}%)"
	end
	puts "#{ballot.current_total} votes remaining in count"
	puts
end

def print_current_votes(ballot)

	display_candidates = ballot.candidates.sort_by { |x| x.cur_votes + (x.elected_order * 1000)}.reverse

	display_candidates.each do |c|
		if c.excluded
			next
		end
		puts "	Candidate #{c.name} is on #{c.cur_votes.round(1)} votes. #{' ## elected ' + c.elected_order.to_s + ' ##' unless c.elected == false}"
				# (or #{(c.cur_votes.to_f / ballot.current_total * 100).round(2)}%)
	end
	puts "#{ballot.current_total} votes remaining in count. #{ballot.current_exhaust} votes have exhausted. #{ballot.cur_candidate_count} candidates remaining"
	puts
end

def check_for_winner(ballot)
	number_to_win = ballot.quota
	
	ballot.candidates.each do |c|
		if c.excluded
			next
		end
		if c.cur_votes >= number_to_win
			puts "Candiate #{c.name} is the winner! They won with #{c.cur_votes} votes which was #{(c.cur_votes.to_f / ballot.current_total * 100).round(2)}%"
			puts
			ballot.has_winner = true
		end
	end
end

def check_for_elected(ballot,round)
	elected = Array.new
	display_candidates = ballot.candidates.sort_by { |x| x.cur_votes }.reverse

	display_candidates.each do |c|
		if c.excluded || c.elected
			next
		end
		if c.cur_votes >= ballot.quota
			c.elected = true
			ballot.candidates_elected += 1
			c.elected_order = ballot.candidates_elected
			elected << c
			puts "Candidate #{c.name} has been elected."
		end
	end
	return elected
end

def find_lowest(ballot)
	lowest = ""
	lowest_votes = Float::INFINITY

	ballot.candidates.each do |c|
		if c.excluded || c.elected
			next
		end
		if c.cur_votes < lowest_votes
			lowest_votes = c.cur_votes
			lowest = c
		end
	end
	lowest.excluded = true
	ballot.cur_candidate_count -= 1
	# puts "Candidate #{lowest.name} has the least votes. Their votes will now be distributed."
	return lowest
end

def distribute_votes(ballot,round,candidate)

	puts "Distributing the votes of #{candidate.name}."

	cnt = 0.0
	tmp = []
	transfer_value = 1.0

	ballot.votes.each do |v|
		if v.is_formal == false || v.is_exhaust
			next
		end
		if v.cur_candidate == candidate.position - 1
			cur_pref = v.order[candidate.position - 1].to_i

			ballot.candidates.count.times do |t|
				next_pref = (cur_pref + 1 + t).to_s
				if not v.order.count(next_pref) == 1
					v.is_exhaust = true
					v.cur_candidate = nil
					ballot.current_exhaust += v.value
					# cnt -= 1
					break
				end
				if ballot.candidates[v.order.index(next_pref)].excluded || ballot.candidates[v.order.index(next_pref)].elected
					next
				else
					# ballot.candidates[v.order.index(next_pref)].cur_votes += 1
					v.cur_candidate = v.order.index(next_pref)
					tmp << v
					# cnt += 1
					break
				end

			end
		else
			cnt += 1
		end
		
	end

	if candidate.elected
		transfer_value = (candidate.cur_votes - ballot.quota) / tmp.count
		candidate.cur_votes = ballot.quota

		tmp.each do |t|
			t.value = (transfer_value )#* t.value)
			ballot.candidates[t.cur_candidate].cur_votes += (transfer_value )#* t.value)
		end

	else
		candidate.cur_votes = 0

		tmp.each do |t|
			ballot.candidates[t.cur_candidate].cur_votes += t.value
		end
	end


	cnt += tmp.count
	ballot.current_total = cnt
	unless ballot.ballot_type == 'pr'
		ballot.quota = ballot.calculate_quota
	end
end