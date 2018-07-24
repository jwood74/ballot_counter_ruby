class String
	def to_b
		case self
		when  true, 'true', 1, '1', 't' then true
		else false
		end
	end
end

def print_first_preference(ballot)
	display_candidates = ballot.candidates.sort_by { |x| x.cur_votes }.reverse

	display_candidates.each do |c|
		puts "	Candidate #{c.name} received #{c.first_pref} first preference votes (or #{c.first_pref_pc.round(2)}%)"
	end
	puts "#{ballot.current_total} votes remaining in count"
	puts
end

def print_current_votes(ballot)

	display_candidates = ballot.candidates.sort_by { |x| x.cur_votes + (x.elected_order * 1000)} #.reverse

	display_candidates.each do |c|
		if c.excluded && c.distributed
			next
		end		# 
		puts "	Candidate #{c.name} is on #{c.cur_votes.round(3)} votes. #{c.young_labor ? '(YL)' : '' } #{' ## elected ' + c.elected_order.to_s + ' ##' unless c.elected == false}"
				# (or #{(c.cur_votes.to_f / ballot.current_total * 100).round(2)}%)
	end
	puts "#{ballot.current_total.round(0)} votes remaining in count. #{ballot.current_exhaust.round(1)} votes have exhausted. #{ballot.cur_candidate_count} candidates remaining"
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

def who_to_distribute(ballot)
	lowest = ""
	lowest_votes = Float::INFINITY
	highest = ""
	highest_votes = Float::INFINITY


	ballot.candidates.each do |c|
		if c.distributed
			next
		end
		if c.cur_votes < lowest_votes and c.elected == false
			lowest_votes = c.cur_votes
			lowest = c
		elsif c.elected == true and c.elected_order < highest_votes and c.cur_votes >= ballot.quota
			highest_votes = c.elected_order
			highest = c
		end

		# elsif c.cur_votes > highest_votes and c.elected and c.distributed == false
		# 	highest_votes = c.cur_votes
		# 	highest = c
		# end
	end

	if highest == ""
		puts "Candidate #{lowest.name} has the least votes. Their votes will now be distributed."
		lowest.excluded = true
		ballot.cur_candidate_count -= 1
		return lowest
	else
		return highest
	end
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
					if candidate.elected == false
						ballot.current_exhaust += v.value
					else
						# cnt += 1
					end
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
			# cnt += 1
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


	# cnt += tmp.count
	# ballot.current_total = cnt
	unless ballot.ballot_type == 'pr'
		ballot.quota = ballot.calculate_quota
	end
	ballot.current_total = 0
	ballot.candidates.each do |c|
		if c.excluded
			next
		end
		ballot.current_total += c.cur_votes
	end
	candidate.distributed = true
end

def check_for_aa(ballot)
	if ballot.female_needed > 0
		f_have = 0
		f_remaining = 0
		ballot.candidates.each do |c|
			if c.female && c.elected
				f_have += 1
			elsif c.female && c.elected == false && c.excluded == false
				f_remaining += 1
			end
		end

		if (ballot.female_needed - f_have) > 0
			if f_remaining == (ballot.female_needed - f_have)
				 ## all remaining females elected
				 ballot.candidates.each do |c|
				 	if c.female && c.elected == false && c.excluded == false
				 		c.elected = true
				 		ballot.candidates_elected += 1
						c.elected_order = ballot.candidates_elected
				 		puts "## AA Elected - #{c.name} - Gender"
				 	end
				 end
			elsif (ballot.female_needed - f_have) >= (ballot.candidates_to_elect - ballot.candidates_elected)
				 ballot.candidates.each do |c|
				 	if c.female == false && c.elected == false && c.excluded == false
				 		puts "## AA Excluded - #{c.name} - Gender"
				 		c.excluded = true
				 	end
				 end
			end
		end
	end

	if ballot.young_labor_needed > 0
		yl_have = 0
		yl_remaining = 0
		ballot.candidates.each do |c|
			if c.young_labor && c.elected
				yl_have += 1
			elsif c.young_labor && c.elected == false && c.excluded == false
				yl_remaining += 1
			end
		end

		if (ballot.young_labor_needed - yl_have) > 0
			if yl_remaining == (ballot.young_labor_needed - yl_have)
				 ## all remaining females elected
				 ballot.candidates.each do |c|
				 	if c.young_labor && c.elected == false && c.excluded == false
				 		c.elected = true
				 		ballot.candidates_elected += 1
						c.elected_order = ballot.candidates_elected
				 		puts "## AA Elected - #{c.name} - Young Labor"
				 	end
				 end
			elsif (ballot.young_labor_needed - yl_have) >= (ballot.candidates_to_elect - ballot.candidates_elected)
				 ballot.candidates.each do |c|
				 	if c.young_labor == false && c.elected == false && c.excluded == false
				 		puts "## AA Excluded - #{c.name} - Young Labor"
				 		c.excluded = true
				 	end
				 end
			end
		end
	end



end

def display_final_result(ballot)
	puts
	puts "The result of the ballot is - "

	display_candidates = ballot.candidates.sort_by { |x| x.elected_order }

	display_candidates.each do |c|
		if c.elected
			puts "#{c.elected_order} - #{c.name}"
		end
	end
end