# (gnu)plot comparing scalability of the various algorithms

set terminal pdf
set output 'data/avg-steps-until-timeout.pdf'

set title "Average Steps Until Timeout"
set xlabel "Number of steps completed"
set ylabel "Timeout (s)"

set key box opaque top left
set style data lines

set grid y
set logscale x

plot \
  'data/avg-steps-until-timeout.csv' using 2:1 title "Enumerate"   with lines lt 1, \
  'data/avg-steps-until-timeout.csv' using 3:1 title "Symbolic"    with lines lt 2, \
  'data/avg-steps-until-timeout.csv' using 4:1 title "Symbolic -r" with lines lt 3, \
  'data/avg-steps-until-timeout.csv' using 5:1 title "Saturate"    with lines lt 4, \
  'data/avg-steps-until-timeout.csv' using 6:1 title "Saturate -r" with lines lt 5
