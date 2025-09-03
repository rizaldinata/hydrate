man(marcus).
pompeian(marcus).
birth(marcus, 40).
mortal(M) :- man(M).
dead(D) :- mortal(D), age(D, AGE), AGE > 150.
dead(D):- pompeian(D), year(Y), Y > 79.
year(2002).
age(NAMA, AGE):-birth(NAMA, BIRTH), year(Y), AGE is Y-BIRTH.