# Ugly Bessy: Beta version 0.0.3
# Authors: Thomas Philip Runarsson and Asgeir Orn Sigurpalsson
# Last modified by tpr 13/9/2017

# TODO:

param minstudent := 0;

#-----------------------------------PARAMETERS AND SETS----------------------------------------#
# number of exam days
param n;

# set of exams to be assigned to exam slots
set CidExam;
set CidExamInclude within CidExam; # Experiment to create more sophisticated phase one optimization

# set of all ExamSlots
set ExamSlots:= 1..(2*n);
param SlotNames{ExamSlots}, symbolic;

# The days in terms of first exam slot of the day
set Days:= 1..(2*n)-1 by 2;

# Maximum number of exam seats
param MaxSeats:= 1200; # was 1295
param maxStudentSeats default 1200;
param minStudentSeats default 800;

# Indicator for exam slot that tell us if the day before is a free day
#param dayBeforeHoliday {e in ExamSlots} := if (e in {1,2,7,8}) then 1 else 0;
#param dayBeforeWeekend {e in ExamSlots} := if (e in {1,2,7,8}) then 1 else 0;
param dayBeforeHoliday{ExamSlots};
param dayBeforeWeekend{ExamSlots};

# Set of all Computer Courses
set ComputerCourses within CidExam default {};

# Courses that should not be assigned to seats
set CidMHR within CidExam default {};

#Total number of students for each course
param cidCount{CidExam} default 0;
# The long number identification for the exam
param CidId{CidExam};

#Total number of Special students for each course
param SpeCidCount{CidExam} default 0;
#Set of all Exams with special students
set SpecialExams := setof{c in CidExam: SpeCidCount[c] > 0} c;

param meanSeats := ceil(sum{c in CidExam: c not in CidMHR} cidCount[c] / card(ExamSlots));
display meanSeats;

display max{cc in ComputerCourses} cidCount[cc];

# course incidence data to constuct the matrix for courses that should be examined together"

param cidConjoinedData {CidExam, CidExam};
# The set of courses that should be examined together, this script forces symmetry for the matrix (if needed)
param cidConjoined  {c1 in CidExam, c2 in CidExam} := min(cidConjoinedData[c1,c2] + cidConjoinedData[c2,c1],1);

# Indicator tells us the course is in a conjoined set
param cidIsConjoined {c in CidExam} :=  min(sum{ce in CidExam} cidConjoined[c,ce],1);

# Number of students taking two common courses"
param CidCommonStudents {CidExam, CidExam} default 0;
# Make sure this matrix is symmetric
param CidCommon {c1 in CidExam, c2 in CidExam} := max(CidCommonStudents[c1,c2],CidCommonStudents[c2,c1]);

# Strict indicator based on curricula or minmumber of students
param CidCommonGroupStudents {CidExam,CidExam} default 0;
param CidCommonGroup {c1 in CidExam, c2 in CidExam} := max(CidCommonGroupStudents[c1,c2],CidCommonGroupStudents[c2,c1]);
param Strict {c1 in CidExam, c2 in CidExam} := if (CidCommon[c1,c2] > minstudent or (CidCommonGroup[c1,c2] == 1 and CidCommon[c1,c2] > 0)) then 1 else 0;

display sum{c1 in CidExam, c2 in CidExam: c1 < c2} Strict[c1,c2];

# This is used to fix any part of the solution or all (may be used for comparison)
set fixsolution{CidExam} within ExamSlots default {};
# Fest út úr Uglu kerfi
set festa{CidExam} within ExamSlots default {};

# Requested time slots by teachers or department
set fixslot{c in CidExam} within  ExamSlots default {};

#-----------------------------------Tolerances and Parameters---------------------------------#

# Parameter used for semi-hard constraint, need to be big because of Law dept.
#Tolerance for the number of common students having no free day before an exam
param tolerance, default 20;

# Tolerance for the number of common students having same day exams
param tolerancesame, default 4;

param toleranceclash, default 0;

#-----------------------------------Decision variables----------------------------------------#

# The decision variable is to assign an exam to an exam slot (later we may add room assignments)
var Slot {CidExam, ExamSlots} binary;

# Indicator variable informs us if the cource c has a student taking two exams that time slot, 0 hour
var Zclash {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1} >= 0;

# Indicator variable that informs if the course c does not have a free day before the exam, 48 hour
var Zday {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and cidConjoined[c1,c2] != 1 and c1 < c2 and Strict[c1,c2] == 1} >= 0;

# Indicator variable informs us if the cource c has a student taking two exams that same day, 12 hour
var Zsame {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1} >= 0;

# Indicator variable informs us if the cource c has a student taking two exams in a row (overnights), 24 hour
var Zseq {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1} >= 0;

# Indicator variable informs us if the cource c has a student taking two exams in a 72 hour period
var Ztwo {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1 and Strict[c1,c2] == 1} >= 0;

#-----------------------------------Hard Constraints----------------------------------------#

# This constraint is used to fix solution (used to display result with glpsol)
subject to fixme {c in CidExam, e in fixsolution[c]}: Slot[c,e] = 1;

# This constraint is used to fix solution requested from Ugla
#subject to fixmeUgla {c in CidExam, e in festa[c]}: Slot[c,e] = 1;

# Fixes the slots that may be required by the courses or departments
# card(festa[c]) == 0 and
subject to FixCourseSlot{c in CidExam: card(fixslot[c])>0}: sum{e in fixslot[c]} Slot[c,e] = 1;

# Hard constraint 1: One and only one of the exams may be assigned
subject to ThereCanBeOnlyOne{c in CidExam}: sum{e in ExamSlots} Slot[c,e] = 1;

# Hard constraint 2: This constraint makes sure that any of the conjoined courses have the same assignment
subject to ConjoinedCourses {c1 in CidExam, c2 in CidExam, e in ExamSlots: !(card(fixslot[c1])==1 and card(fixslot[c2])==1) and c1 < c2 and cidConjoined[c1,c2] == 1}: Slot[c1,e] = Slot[c2,e];

# Hard constraint 2: Students can't take any two exams at the same time, unless forced to do so?!
# There may be an option here later to relax those that are not strict
subject to NoStudentClash {e in ExamSlots, c1 in CidExam, c2 in CidExam:
     !(card(fixslot[c1]) == 1 and card(fixslot[c2]) == 1) and
     CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1 }:
     Slot[c1, e] + Slot[c2, e] <= 1;

# Semi-hard constraints 1: At some tolerance we dont want students taking more than one exam the same day
subject to NotTheSameDay {c1 in CidExam, c2 in CidExam, e in Days: !(card(fixslot[c1])==1 and card(fixslot[c2])==1) and
   CidCommon[c1,c2] > tolerancesame and c1 < c2 and cidConjoined[c1,c2] != 1}:
  (Slot[c1, e] + Slot[c2, e] + Slot[c1,e+1] + Slot[c2,e+1]) <= 1;

subject to NotTheSameDayGroup {c1 in CidExam, c2 in CidExam, e in Days: !(card(fixslot[c1])==1 and card(fixslot[c2])==1) and
  (CidCommonGroup[c1,c2] == 1 or CidCommon[c1,c2] >= 70) and CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1}:
    (Slot[c1, e] + Slot[c2, e] + Slot[c1,e+1] + Slot[c2,e+1]) <= 1;

# Semi-hard version up to tolerance of taking exams in a row
subject to NotTheSameNight {c1 in CidExam, c2 in CidExam, e in Days: 1 != dayBeforeHoliday[e] and !(card(fixslot[c1])==1 and card(fixslot[c2])==1)
  and CidCommon[c1,c2] > tolerancesame and c1 < c2 and cidConjoined[c1,c2] != 1}:
     (Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e-1] + Slot[c1, e]) <= 1;

subject to NotTheSameNightGroup {c1 in CidExam, c2 in CidExam, e in Days: 1 != dayBeforeHoliday[e] and !(card(fixslot[c1])==1 and card(fixslot[c2])==1)
   and (CidCommonGroup[c1,c2] == 1 or CidCommonGroup[c1,c2] >= 70) and CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1}:
      (Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e-1] + Slot[c1, e]) <= 1;

# Semi-hard Will tell us when a course does not have a free day before a scheduled exam
subject to RestDayBeforeHardTol {c1 in CidExam, c2 in CidExam, e in Days: 1 != dayBeforeHoliday[e] and !(card(fixslot[c1])==1 and card(fixslot[c2])==1)
  and e > 2 and CidCommon[c1,c2] > tolerance and cidConjoined[c1,c2] != 1 and c1 < c2}:
           Slot[c2, e-2] + Slot[c2, e-1] + Slot[c1, e] + Slot[c1, e+1] + Slot[c1, e-2] + Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e+1] <= 1;

subject to RestDayBeforeGroup {c1 in CidExam, c2 in CidExam, e in Days: 1 != dayBeforeHoliday[e] and !(card(fixslot[c1])==1 and card(fixslot[c2])==1)
   and e > 2 and CidCommonGroup[c1,c2] == 1 and CidCommon[c1,c2] > 4 and cidConjoined[c1,c2] != 1 and c1 < c2 and Strict[c1,c2] == 1}:
     Slot[c2, e-2] + Slot[c2, e-1] + Slot[c1, e] + Slot[c1, e+1] + Slot[c1, e-2] + Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e+1] <= 1;



#-----------------------------------Capacity Constraints-------------------------------------#

#The maximum number of seats available
subject to MaxInSlot {e in ExamSlots}: sum{c in CidExam: c not in CidMHR} Slot[c,e] * cidCount[c] <= maxStudentSeats;
subject to MinInSlot {e in ExamSlots}: sum{c in CidExam: c not in CidMHR} Slot[c,e] * cidCount[c] >= minStudentSeats;

#The maximum number that can be assiged to computer exams per day
subject to ComputerCap {e in ExamSlots}: sum{c in ComputerCourses} Slot[c,e]*cidCount[c] <= max{cc in ComputerCourses} cidCount[cc]; #145

subject to SpecialComputerCap {e in ExamSlots}: sum{c in ComputerCourses} Slot[c,e]*SpeCidCount[c] <= 38;

#The maximum number of special students that can be assigned per slot
subject to SpecialCap {e in ExamSlots}: sum{c in SpecialExams} Slot[c,e]*SpeCidCount[c] <= 124;

# Just one big exam in each Slot at a time, due to room capacities, remove condition of fixslot ?!
var maxnumberofbigcoursesperslot >= 0;
subject to OneBigCourse{e in ExamSlots}: sum{c in CidExam: cidCount[c]>120} Slot[c,e] <= maxnumberofbigcoursesperslot;

#-----------------------------------Soft Constraints------------------------------------------#

# Soft Constraint - indicates if students are taking two Exams the same time slot
subject to StudentClash {c1 in CidExam, c2 in CidExam, e in ExamSlots:
  CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1}: (Slot[c1, e] + Slot[c2, e]) - 1 <= Zclash[c1,c2];

#Soft Constraint - Will tell us when a course does not have a free day before a scheduled exam
subject to RestDayBefore {c1 in CidExam, c2 in CidExam, e in Days:  Strict[c1,c2] == 1 and
    1 != dayBeforeHoliday[e] and e > 2 and CidCommon[c1,c2] > 0 and cidConjoined[c1,c2] != 1 and c1 < c2}:
    Slot[c2, e-2] + Slot[c2, e-1] + Slot[c1, e] + Slot[c1, e+1] + Slot[c1, e-2] + Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e+1] - 1 <= Zday[c1,c2];

#Soft Constraint - Students should not have two exams the same day
subject to NotTheSameDaySoft{c1 in CidExam, c2 in CidExam, e in Days:  #Strict[c1,c2] == 1 and
  CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1}:
  (Slot[c1, e] + Slot[c2, e] + Slot[c1,e+1] + Slot[c2,e+1]) - 1 <= Zsame[c1,c2];

#Students should not sit two consecutives examinations i.e. two exams in a row - same day or less than 24h laters
subject to NotTheSameNightSoft{c1 in CidExam, c2 in CidExam, e in Days:  #Strict[c1,c2] == 1 and
  1 != dayBeforeHoliday[e] and CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1}:
   (Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e-1] + Slot[c1, e]) - 1 <= Zseq[c1,c2];

subject to TwoDayRestSoft {c1 in CidExam, c2 in CidExam, e in Days: e > 4 and Strict[c1,c2] == 1 and 1 != dayBeforeHoliday[e]
  and 1 != dayBeforeHoliday[e-2] #and !(card(festa[c1])>0 and card(festa[c2])>0)
        and CidCommon[c1,c2] > 0 and cidConjoined[c1,c2] != 1 and c1 < c2}:
          Slot[c2, e-4] + Slot[c2, e-3] + Slot[c2, e-2] + Slot[c2, e-1] + Slot[c1, e] + Slot[c1, e+1]
        + Slot[c1, e-4] + Slot[c1, e-3] + Slot[c1, e-2] + Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e+1] <= Ztwo[c1,c2];


#-----------------------------------Collection of Info------------------------------------------#

#Displays the number of students having two exams the same day
var obj1;
var obj1x;
subject to O1: obj1 = sum{c1 in CidExam, c2 in CidExam: (CidCommonGroup[c1,c2] == 1 or CidCommon[c1,c2] >= 70) and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1} CidCommon[c1,c2] * Zsame[c1,c2];
subject to O1x: obj1x = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1} CidCommon[c1,c2] * Zsame[c1,c2];

#subject to O1y: obj1 <= 50;

#Displays the number of students having two consecutives examinations i.e. the same day or within 24 hours (afternoon and morning day after)
var obj2;
var obj2x;
subject to O2: obj2 = sum{c1 in CidExam, c2 in CidExam: (CidCommonGroup[c1,c2]  == 1 or CidCommon[c1,c2] >= 70) and CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1} CidCommon[c1,c2] * Zseq[c1,c2];
subject to O2x: obj2x = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1} CidCommon[c1,c2] * Zseq[c1,c2];

#Displays the number of students not receiving one day for preparation for a day
var obj3;
var obj3x;
subject to O3: obj3 = sum{c1 in CidExam, c2 in CidExam: (CidCommonGroup[c1,c2] == 1 or CidCommon[c1,c2] >= 70) and CidCommon[c1,c2] > 0 and cidConjoined[c1,c2] != 1 and c1 < c2} CidCommon[c1,c2] * Zday[c1,c2];
subject to O3x: obj3x = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and Strict[c1,c2] == 1 and cidConjoined[c1,c2] != 1 and c1 < c2} CidCommon[c1,c2] * Zday[c1,c2];
#subject to O3x: obj3 <= 300;

#Displays the number of students having two exams in the same timeslot
var obj4;
subject to O4: obj4 = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1} CidCommon[c1,c2] * Zclash[c1,c2];

var obj5;
var obj5x;
subject to O5: obj5 = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 70 and c1 < c2 and cidConjoined[c1,c2] != 1} CidCommon[c1,c2] * Ztwo[c1,c2];
subject to O5x: obj5x = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and Strict[c1,c2] == 1 and c1 < c2 and cidConjoined[c1,c2] != 1} CidCommon[c1,c2] * Ztwo[c1,c2];

#-----------------------------------Objective Function------------------------------------------#

minimize Objective: 1000*obj1+500*obj2+400*obj3+10*obj1x+50*obj2x+1*obj3x+100000*obj4+10*obj5+0.1*obj5x+100*maxnumberofbigcoursesperslot;

solve;

#-----------------------------------Print Phase---------------------------------------------------#

# pretty print the solution

printf : "Fjöldi raun prófsæta: (dags = )\n" > "stats.txt";
for {e in ExamSlots} {
  printf : "%s = %d\n", SlotNames[e], sum{c in CidExam: c not in CidMHR} Slot[c,e] * cidCount[c] >> "stats.txt";
}

printf : "Fjöldi tölvu prófsæta: (dags = )\n" >> "stats.txt";
for {e in ExamSlots} {
  printf : "%s = %d\n", SlotNames[e], sum{c in ComputerCourses} Slot[c,e] * cidCount[c] >> "stats.txt";
}

printf : "Heildarfjöldi prófa er %d og þreytt próf eru %.0f.\n", card(CidExam), sum{c in CidExam} cidCount[c] >> "stats.txt";
printf : "Lenda í prófi samdægurs: %.0f (%.2f%%)\n", obj1x, 100*obj1x/(sum{c in CidExam} cidCount[c]) >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: Strict[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zsame[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";
printf : "þar af nemendur á námsbraut:\n" >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: CidCommonGroup[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zsame[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";
printf : "þar af þvingað af stjórnsýslu:\n" >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: (card(fixslot[c1])>0 and card(fixslot[c2])>0) and Strict[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zsame[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";
printf : "Taka próf eftir hádegi og svo strax morguninn eftir: %.0f (%.2f%%)\n", obj2x, 100*obj2x/(sum{c in CidExam} cidCount[c]) >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: Strict[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zseq[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";
printf : "þar af nemendur á námsbraut:\n" >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: CidCommonGroup[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zseq[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";
printf : "þar af þvingað af stjórnsýslu:\n" >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: (card(fixslot[c1])>0 and card(fixslot[c2])>0) and Strict[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zseq[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";
printf : "Þreyta próf tvo daga í röð: %.0f (%.2f%%).\n", obj3x, 100*obj3x/(sum{c in CidExam} cidCount[c]) >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: Strict[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zday[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";
printf : "þar af nemendur á námsbraut:\n" >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: CidCommonGroup[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zday[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";
printf : "þar af þvingað af stjórnsýslu:\n" >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: (card(fixslot[c1])>0 and card(fixslot[c2])>0) and Strict[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zday[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";
printf : "Þreyta tvö próf innan þrjá daga í röð: %.0f (%.2f%%).\n", obj5, 100*obj5/(sum{c in CidExam} cidCount[c]) >> "stats.txt";
printf {c1 in CidExam, c2 in CidExam: Strict[c1,c2] == 1 and CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Ztwo[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2] >> "stats.txt";

#printf : "Lausnin:\n";
param SlotTime{e in ExamSlots} := str2time(SlotNames[e], "%y-%m-%d %H:%M:%S");
printf {e in ExamSlots, c in CidExam: Slot[c,e] > 0}: "%011.0f;20%s;20%s\n", CidId[c], SlotNames[e], time2str(SlotTime[e] + 3*60*60,"%y-%m-%d %H:%M:%S")  > "lausn.csv";
printf {e in ExamSlots, c in CidExam: Slot[c,e] > 0}: "%d;%s;%011.0f;20%s;20%s\n", e, c, CidId[c], SlotNames[e], time2str(SlotTime[e] + 3*60*60,"%y-%m-%d %H:%M:%S")  > "lausn.txt";

end;
