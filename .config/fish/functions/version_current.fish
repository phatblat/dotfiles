# 
function version_current
      local build_version market_version
  build_version=$(version_build)
  market_version=$(version_market)
  echo "$market_version ($build_version)" $argv
end
