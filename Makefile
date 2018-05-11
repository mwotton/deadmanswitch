retest:
	HSPEC_OPTIONS="--format=progress --failure-report=.hspec-failures --rerun --rerun-all-on-success" ghcid --test=":main" -c "stack ghci :spec deadmanswitch:lib deadmanswitch:test:spec --ghci-options -Wwarn"  

alltest:
	HSPEC_OPTIONS="--format=progress" ghcid --test=":main" -c "stack ghci :spec deadmanswitch:lib deadmanswitch:test:spec --ghci-options -Wwarn"  
