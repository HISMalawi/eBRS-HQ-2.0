def pretty_date(stamp)
	now = Time.new
	diff = now - stamp
	day_diff = ((now - stamp) / 86400).floor

	day_diff == 0 && (
		diff < 60 && "just now" ||
		diff < 120 && "1 minute ago" ||
		diff < 3600 && (diff / 60).floor.to_s + " minutes ago" ||
		diff < 7200 && "1 hour ago" ||
		diff < 86400 && (diff/3600).floor.to_s + " hours ago") ||
	day_diff == 1 && "Yesterday" ||
	day_diff < 7 && day_diff.to_s + " days ago" ||
  day_diff < 31 && (day_diff/7).ceil.to_s + " weeks ago";
end
