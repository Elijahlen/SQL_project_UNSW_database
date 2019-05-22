-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution Template

create or replace view Local(id)
as
select id from students where stype = 'local'
;
create or replace view Intl(id)
as
select id from students where stype = 'intl'
;

-- Q1: 
create or replace view Q1_1_x(student,mark)
as
select student,mark from course_enrolments
where mark>=85
;
create or replace view Q1_2_x(student)
as
select student from Q1_1_x           
group by student
having count(mark)>20
;
create or replace view Q1_3_x(student)
as
select student from Q1_2_x
where student in (select * from Intl)
;
create or replace view Q1(unswid,name)
as
select unswid,name from people,Q1_3_x
where student = id
;


-- Q2: 
create or replace view Q2(unswid,name)
as
select rooms.unswid,longname from rooms,buildings,room_types
where capacity>=20 and capacity is not null and rtype = room_types.id and
description = 'Meeting Room' and building = buildings.id and 
buildings.name = 'Computer Science Building' 
;



-- Q3: 
create or replace view Q3(unswid, name)
as
select second.unswid,second.name
from people second,people first,course_staff,course_enrolments
where first.sortname = 'Stefan Bilek' and
first.id = student and
course_enrolments.course = course_staff.course and
staff = second.id
;



-- Q4:
create or replace view Q4_2(id)
as
select student
from course_enrolments where course in (select courses.id from courses,subjects where subject = subjects.id and code = 'COMP3231')
group by student
;
create or replace view Q4_1(id)
as
select student
from course_enrolments where course in (select courses.id from courses,subjects where subject = subjects.id and code = 'COMP3331')
group by student
;
create or replace view Q4_1_2(id)
as
select * from Q4_1
except                                         
select * from Q4_2
;
create or replace view Q4(unswid, name)
as
select unswid,name
from people,Q4_1_2 where people.id = Q4_1_2.id
;

-- Q5: 

create or replace view Q5a_1(id) as select distinct student
from program_enrolments,stream_enrolments,semesters where semester = semesters.id and year = '2011' and term = 'S1' and
program_enrolments.id = partof and  stream in (
select id from streams where name = 'Chemistry')
;
create or replace view Q5a(num)
as
select count(*)
from Q5a_1, Local
where Q5a_1.id = Local.id
;

-- Q5: 
create or replace view Q5b_1(id)
as
select distinct student 
from program_enrolments, semesters
where semester = semesters.id and year = '2011' and term = 'S1' and program in (select programs.id from
programs,orgunits where offeredby = orgunits.id and longname = 
'School of Computer Science and Engineering')
;
create or replace view Q5b(num)
as
select count(*)
from Q5b_1,Intl
where Q5b_1.id = Intl.id
;

-- Q6:
create or replace function
	Q6(text) returns text
as
$$
select distinct code||' '||name||' '||uoc
from subjects
where code = $1
$$ language sql
;



-- Q7: 
create or replace view Q7_all(program,count)
as
select program,count(student)
from program_enrolments
group by program 
;
create or replace view Q7_intl_table(program,student)
as
select program,student 
from program_enrolments where student in (select * from Intl)
;
create or replace view Q7_intl(program,count)
as
select program,count(student)
from Q7_intl_table
group by program
;
create or replace view Q7_1(id)   
as 
select Q7_all.program
from Q7_all,Q7_intl
where Q7_all.program = Q7_intl.program and Q7_intl.count/Q7_all.count ::numeric >0.5
;
create or replace view Q7(code, name)
as
select code,name from Q7_1,programs 
where Q7_1.id = programs.id 
;



-- Q8:
create or replace view Q8_shu(course,count)
as
select course,count(mark) from course_enrolments
where mark is not null
group by course
;
create or replace view Q8_shai(course)
as
select course
from Q8_shu
where count>=15
;
create or replace view Q8_1(course)
as
select course_enrolments.course 
from course_enrolments,Q8_shai
where course_enrolments.course = Q8_shai.course
group by course_enrolments.course
having avg(mark) >=all(select avg(mark)
from course_enrolments,Q8_shai where course_enrolments.course = Q8_shai.course
group by course_enrolments.course)
;
create or replace view Q8(code, name, semester)
as
select
code,subjects.name,semesters.name
from courses,subjects,semesters,Q8_1
where Q8_1.course = courses.id and subject = subjects.id and semester = semesters.id 
;

-- Q9:
create or replace view Q9_s(id,count)
as
select staff,count(distinct code)
from course_staff,subjects,courses
where course = courses.id and subject = subjects.id
group by staff
;
create or replace view Q9_orgid(id)
as
select orgunits.id from orgunits,orgunit_types 
where orgunit_types.name = 'School' and orgunit_types.id = utype
;
create or replace view Q9_shai(id,orgid,starting,count)
as
select Q9_s.id,orgunit,starting,count
from Q9_s,affiliations,staff_roles
where Q9_s.id=staff  and role = staff_roles.id and staff_roles.name = 'Head of School' and isprimary = 't' and ending is null 
and orgunit in (select * from Q9_orgid)
;

create or replace view Q9(name, school, email, starting, num_subjects)
as
select distinct people.name,longname,people.email,Q9_shai.starting,count
from people,Q9_shai,affiliations,orgunits 
where Q9_shai.id = people.id and Q9_shai.orgid = orgunits.id and Q9_shai.id = affiliations.staff
;


-- Q10:
create or replace view Q10_2(course,count)
as
select course,count(mark)
from course_enrolments
where mark>=0
group by course
;
create or replace view Q10_1(course,count)
as
select course,count(mark)
from course_enrolments                                           
where mark>=85
group by course
;
create or replace view Q10_1_1(course,count)
as
select Q10_2.course,Q10_1.count
from Q10_2 left outer join Q10_1 on(Q10_2.course = Q10_1.course)
;
create or replace view Q_3(course,ratio)
as
select Q10_2.course,coalesce(((Q10_1_1.count*1.0/Q10_2.count*1.0)::numeric(4,2)),0.00)
from Q10_2,Q10_1_1
where Q10_2.course = Q10_1_1.course
;
create or replace view Q10_s1(course,code,year,S1_HD_rate)
as                                                        
select Q_3.course,code,substring(cast(year as text),3,2),Q_3.ratio
from Q_3 ,subjects s1,courses c1,semesters e1 where Q_3.course = c1.id and c1.subject = s1.id and s1.code like 'COMP93%' and      
c1.semester = e1.id and e1.year between 2003 and 2012 and term = 'S1' order by code,year
;
create or replace view Q10_s2(course,code,year,S2_HD_rate)
as
select Q_3.course,code,substring(cast(year as text),3,2),Q_3.ratio
from Q_3 ,subjects s1,courses c1,semesters e1 where Q_3.course = c1.id and c1.subject = s1.id and s1.code like 'COMP93%' and
c1.semester = e1.id and e1.year between 2003 and 2012 and term = 'S2' order by code,year
;
create or replace view Q10_s1_s2(code,year,S1_HD_rate,S2_HD_rate)
as
select Q10_s1.code,Q10_s1.year,Q10_s1.S1_HD_rate,Q10_s2.S2_HD_rate
from Q10_s2,Q10_s1
where Q10_s2.code = Q10_s1.code and Q10_s2.year = Q10_s1.year
;
create or  replace view Q10_s1_s2_mode(code)
as
select code 
from Q10_s1_s2 group by code having count(*) = 10
;
create or replace view Q10_final(code,year,S1_HD_rate,S2_HD_rate)
as
select Q10_s1_s2.code,year,S1_HD_rate,S2_HD_rate
from Q10_s1_s2_mode,Q10_s1_s2 
where Q10_s1_s2.code = Q10_s1_s2_mode.code
;
create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
select  Q10_final.code,name,year,S1_HD_rate,S2_HD_rate
from Q10_final,subjects
where Q10_final.code = subjects.code
;

