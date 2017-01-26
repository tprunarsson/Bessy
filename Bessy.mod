# Messy Bessy: Beta version 0.0.1
# Authors: Thomas Philip Runarsson and Asgeir Orn Sigurpalsson
# Last modified by aos at 15:03 20/9/2016
# Last modified by tpr at 13:55 23/9/2016

# TODO:

#-----------------------------------PARAMETERS AND SETS----------------------------------------#
# this parameter splits the runs into two phases
param phase := 0;

#number of exam days
param n:= 11;

#set of exams to be assigned to exam slots
set CidExam;
set CidExamInclude within CidExam; # Experiment to create more sophisticated phase one optimization

#set of all ExamSlots
set ExamSlots:= 1..(2*n);
param SlotNames{ExamSlots}, symbolic;

#The days in terms of first exam slot of the day
set Days:= 1..(2*n)-1 by 2;

#Maximum number of exam seats
param MaxSeats:= 1160; # was 1295

#Indicator for exam slot that tell us if the day before is a free day
# Free days before (1,2) 25th april, (9,10) 2nd May and (17,18) 8th of May
param dayBeforeHoliday {e in ExamSlots} := if (e in {1,2,9,10,17,18}) then 1 else 0;

#Set of all Computer Courses
set ComputerCourses within CidExam;

#Courses that should not be assigned to seats
set CidMHR within CidExam;

set RequiredSlots{CidExam} default {}; #UT

#Total number of students for each course
param cidCount{CidExam} default 0;
# The long number identification for the exam
param CidId{CidExam};

#Total number of Special students for each course
param SpeCidCount{CidExam} default 0;
#Set of all Exams with special students
set SpecialExams := setof{c in CidExam: SpeCidCount[c] > 0} c;

# course incidence data to constuct the matrix for courses that should be examined together"

param cidConjoinedData {CidExam, CidExam};
# The set of courses that should be examined together, this script forces symmetry for the matrix (if needed)
param cidConjoined  {c1 in CidExam, c2 in CidExam} := min(cidConjoinedData[c1,c2] + cidConjoinedData[c2,c1],1);

#Indicator tells us the course is in a conjoined set
param cidIsConjoined {c in CidExam} :=  min(sum{ce in CidExam} cidConjoined[c,ce],1);

#Number of students taking two common courses"
param CidCommonStudents {CidExam, CidExam} default 0;
#Make sure this matrix is symmetric
param CidCommon {c1 in CidExam, c2 in CidExam} := max(CidCommonStudents[c1,c2],CidCommonStudents[c2,c1]);
#Indicator for difficult assignment
param CidCommonSum {c in CidExam} := sum{ce in CidExam} CidCommon[c,ce];

# This is used to fix any part of the solution or all (may be used for comparison)
set fixsolution{CidExam} within ExamSlots default {};

# Requested time slots by teachers or department
set fixslot{c in CidExam} within  ExamSlots default {};


#-----------------------------------Tolerances and Parameters---------------------------------#

# Parameter used for semi-hard constraint, need to be big because of Law dept.
#Tolerance for the number of common students having no free day before an exam
param tolerance, default 100;
#10 works in phase 1 with 200

#Tolerance for the number of common students having same day exams
param tolerancesame, default 10;
#0 works in phase 1 with 200

#-----------------------------------Decision variables----------------------------------------#

# The decision variable is to assign an exam to an exam slot (later we may add room assignments)
var Slot {CidExam, ExamSlots} binary;

# These auxilliary variables/parameters are created to help with the objective of the exam assignment problem /
#The samellest number of students examined for any exam slot
var z>= 0;

#Indicator variable informs us if the cource c has a student taking two exams that time slot
var Zclash {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1} >= 0;

#Indicator variable that informs if the course c does not have a free day before the exam
var Zday {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and cidConjoined[c1,c2] != 1 and c1 < c2} >= 0;

#Indicator variable informs us if the cource c has a student taking two exams that time slot"
var Zsame {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1} >= 0;

#Indicator variable informs us if the cource c has a student taking two exams in a row
var Zseq {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1} >= 0;

#The maximum number of students having computer exams for any exam slots
var w >=0;
#-----------------------------------Hard Constraints----------------------------------------#

# This constraint is used to fix solution - Used for phase 1
subject to fixme {c in CidExam, e in fixsolution[c]}: Slot[c,e] = 1;


#Fixes the slots that may be required by the courses or departments
subject to FixCourseSlot{c in CidExam:card(fixslot[c])>0}: sum{e in fixslot[c]} Slot[c,e] = 1;


# Hard constraint 1: One and only one of the exams may be assigned
                  #----Used 200 for common sum----#

subject to ThereCanBeOnlyOne #Tharf ad tekka med requiredSlots - a ad vera e-ð annad tharna i stadinn?? Ekkert notad
{c in CidExam}: sum{e in ExamSlots} Slot[c,e] = if (card(fixsolution[c])>0 or cidCount[c] > 200 or
   CidCommonSum[c] >= 200*phase or cidIsConjoined[c] == 1 or card(RequiredSlots[c])>0 or card(fixslot[c])>0) then 1 else 0;

# c in CidExamInclude CidCommonSum[c] >= 200

# Hard constraint 2: Students can't take any two exams at the same time

subject to NoStudentClash {e in ExamSlots, c1 in CidExam, c2 in CidExam:
     CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1 and (card(fixslot[c1]) != 1 or card(fixslot[c2]) != 1)}:
     Slot[c1, e] + Slot[c2, e] <= 1;

# Hard constraint 3: This constraint makes sure that any of the conjoined courses have the same assignment
subject to ConjoinedCourses
{c1 in CidExam, c2 in CidExam, e in ExamSlots: c1 < c2 and cidConjoined[c1,c2] == 1}: Slot[c1,e] = Slot[c2,e];

# Semi-hard constraints 1: At some tolerance we dont want students taking more than one exam the same day
subject to NotTheSameDay
  {c1 in CidExam, c2 in CidExam, e in Days: CidCommon[c1,c2] > tolerancesame and c1 < c2 and cidConjoined[c1,c2] != 1
     and (card(fixslot[c1])!=1 and card(fixslot[c2])!=1)}:
  (Slot[c1, e] + Slot[c2, e] + Slot[c1,e+1] + Slot[c2,e+1]) <= 1;

# Semi-hard version up to tolerance of taking exams in a row
subject to NotTheSameNightSoftTolerance{c1 in CidExam, c2 in CidExam, e in Days: 1 != dayBeforeHoliday[e] and CidCommon[c1,c2] > tolerancesame and c1 < c2 and cidConjoined[c1,c2] != 1
    and (card(fixslot[c1])!=1 and card(fixslot[c2])!=1)}:
     (Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e-1] + Slot[c1, e]) <= 1;

# Semi-hard Will tell us when a course does not have a free day before a scheduled exam
subject to RestDayBeforeTolerance
{c1 in CidExam, c2 in CidExam, e in Days: 1 != dayBeforeHoliday[e] and e > 2 and CidCommon[c1,c2] > tolerance and cidConjoined[c1,c2] != 1 and c1 < c2
             and (card(fixslot[c1])!=1 and card(fixslot[c2])!=1)}:
           Slot[c2, e-2] + Slot[c2, e-1] + Slot[c1, e] + Slot[c1, e+1] + Slot[c1, e-2] + Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e+1] <= 1;


#-----------------------------------Capacity Constraints-------------------------------------#

#The maximum number of seats available
subject to MaxInSlot {e in ExamSlots}: sum{c in CidExam: c not in CidMHR} Slot[c,e] * cidCount[c] <= MaxSeats;

#The maximum number that can be assiged to computer exams per day
#subject to ComputerCap {e in ExamSlots}: sum{c in ComputerCourses} Slot[c,e]*cidCount[c] <= 173; #173

#subject to SpecialComputerCap {e in ExamSlots}: sum{c in ComputerCourses} Slot[c,e]*SpeCidCount[c] <= 38;

#The maximum number that can be assiged to computer exams per day

subject to ComputerCapW {e in ExamSlots}: sum{c in ComputerCourses} Slot[c,e]*cidCount[c] <= w; #173

#The maximum number of special students that can be assigned per slot
#subject to SpecialCap {e in ExamSlots}: sum{c in SpecialExams} Slot[c,e]*SpeCidCount[c] <= 125;

# This is a soft objective constraints, count the number of seats needed for the "easiest" day (least number of seats needed at any day)
subject to MaxSeat {e in ExamSlots}: sum{c in CidExam: c not in CidMHR} Slot[c,e] * cidCount[c] >= z;

# Just one big exam in each Slot at a time, due to room capacities
#subject to OneBigCourse{e in ExamSlots}: sum{c in CidExam: cidCount[c]>260 and card(fixslot[c]) != 1} Slot[c,e] <= 1;

#-----------------------------------Soft Constraints------------------------------------------#


#Soft Constraint - indicates if students are taking two Exams the same time slot
subject to StudentClash{c1 in CidExam, c2 in CidExam, e in ExamSlots:
  CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1}: (Slot[c1, e] + Slot[c2, e]) - 1 <= Zclash[c1,c2];

#Soft Constraint - Will tell us when a course does not have a free day before a scheduled exam
subject to RestDayBefore
    {c1 in CidExam, c2 in CidExam, e in Days: 1 != dayBeforeHoliday[e] and e > 2 and CidCommon[c1,c2] > 0 and cidConjoined[c1,c2] != 1 and c1 < c2}:
    Slot[c2, e-2] + Slot[c2, e-1] + Slot[c1, e] + Slot[c1, e+1] + Slot[c1, e-2] + Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e+1] - 1 <= Zday[c1,c2];

#Soft Constraint - Students should not have two exams the same day
subject to NotTheSameDaySoft{c1 in CidExam, c2 in CidExam, e in Days: CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1}:
  (Slot[c1, e] + Slot[c2, e] + Slot[c1,e+1] + Slot[c2,e+1]) - 1 <= Zsame[c1,c2];

#Students should not sit two consecutives examinations i.e. two exams in a row - same day or less than 24h laters

subject to NotTheSameNightSoft{c1 in CidExam, c2 in CidExam, e in Days: 1 != dayBeforeHoliday[e]
  and CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1}:
   (Slot[c1, e-1] + Slot[c2, e] + Slot[c2, e-1] + Slot[c1, e]) - 1 <= Zseq[c1,c2];


#-----------------------------------Collection of Info------------------------------------------#

#Displays the number of students having two exams the same day
var obj1;
subject to O1: obj1 = sum{c1 in CidExam, c2 in CidExam:CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1} CidCommon[c1,c2] * Zsame[c1,c2];
#subject to O1x: obj1 <= 100;

#Displays the number of students having two consecutives examinations i.e. the same day or within 24 hours (afternoon and morning day after)
var obj2;
subject to O2: obj2 = sum{c1 in CidExam, c2 in CidExam:CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1} CidCommon[c1,c2] * Zseq[c1,c2];
#subject to O2x: obj2 <= 300;

#Displays the number of students not receiving one day for preparation for a day
var obj3;
subject to O3: obj3 = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and cidConjoined[c1,c2] != 1 and c1 < c2} CidCommon[c1,c2] * Zday[c1,c2];
#subject to O3x: obj3 <= 300;


#Displays the number of students having two exams in the same timeslot
var obj4;
subject to O4: obj4 = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1  and (card(fixslot[c1]) != 1
  or card(fixslot[c2]) != 1)} CidCommon[c1,c2] * Zclash[c1,c2];

#-----------------------------------Objective Function------------------------------------------#

minimize Objective:
100*obj1+50*obj2+1*obj3+10000*obj4 - 0.0001*z+w
+ sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1} Zclash[c1,c2];


#-----------------------------------Debugging---------------------------------------------------#
var obj1f;
subject to O1f: obj1f = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and
   (card(fixslot[c1])<1 and card(fixslot[c2])<1)} CidCommon[c1,c2] * Zsame[c1,c2];

var obj2f;
subject to O2f: obj2f = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1 and
   (card(fixslot[c1])<1 and card(fixslot[c2])<1)} CidCommon[c1,c2] * Zseq[c1,c2];

var obj3f;
subject to O3f: obj3f = sum{c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2 and cidConjoined[c1,c2] != 1 and
  (card(fixslot[c1])<1 and card(fixslot[c2])<1)} CidCommon[c1,c2] * Zday[c1,c2];


solve;

#-----------------------------------Print Phase---------------------------------------------------#

# pretty print the solution

printf : "Fjöldi raun prófsæta: (dags = )\n";
for {e in ExamSlots} {
  printf : "%s = %d\n", SlotNames[e], sum{c in CidExam: c not in CidMHR} Slot[c,e] * cidCount[c];
}

printf : "Fjöldi tölvu prófsæta: (dags = )\n";
for {e in ExamSlots} {
  printf : "%s = %d\n", SlotNames[e], sum{c in ComputerCourses} Slot[c,e] * cidCount[c];
}

printf : "Heildarfjöldi prófa er %d og þreytt próf eru %.0f.\n", card(CidExam), sum{c in CidExam} cidCount[c];
printf : "Lenda í prófi samdægurs: %.0f (%.2f%%), deildir þvinga %.0f. Prófin eru:\n", obj1, 100*obj1/(sum{c in CidExam} cidCount[c]), obj1-obj1f;
printf {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zsame[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2];
printf : "Taka próf eftir hádegi og svo strax morguninn eftir: %.0f (%.2f%%), deildir þvinga %.0f.\n", obj2, 100*obj2/(sum{c in CidExam} cidCount[c]), obj2-obj2f;
printf {c1 in CidExam, c2 in CidExam: CidCommon[c1,c2] > 0 and c1 < c2  and cidConjoined[c1,c2] != 1 and Zseq[c1,c2] > 0.1}: "%s(%011.0f) og %s(%011.0f) = %d nem.\n", c1,CidId[c1],c2,CidId[c2],CidCommon[c1,c2];
printf : "Þreyta próf tvo daga í röð: %.0f (%.2f%%), deildir þvinga %.0f.\n", obj3, 100*obj3/(sum{c in CidExam} cidCount[c]), obj3-obj3f;
# printf : "Lausnin:\n";
printf {e in ExamSlots, c in CidExam: Slot[c,e] > 0}: "%s;%011.0f;%d;%s\n", c, CidId[c], e, SlotNames[e] > "lausn.csv";

end;
