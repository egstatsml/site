all: publish

publish:
	emacs -Q --batch -l publish.el
	# find html -name "*.html" -exec sed -i 's|href=\"/|href=\"|g' {} +
	# find html -name "*.html" -exec sed -i 's|src=\"/|src=\"|g' {} +
clean-full:
	rm -r html/* .packages/*

clean:
	rm -r html/*
