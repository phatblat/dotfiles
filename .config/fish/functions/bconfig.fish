# 
function bconfig
      bundle config --local clean true
  bundle config --local path .rubygems
  bundle config --local bin bin
  bundle config --local jobs 8 $argv
end
