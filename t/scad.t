use Test::More;

use OpenScad;
use OpenScad::Cylinder;

plan tests => 4;


# Test de OpenScad::Cylinder
is(OpenScad::Cylinder::->new(
       h => 1,
       r => 2)->generate(0),
   "cylinder(h=1, r=2, center=false);");

# Test de OpenScad
my $o = OpenScad::->new();

is($o->intersection(
       $o->cylinder_simple(1, 2),
       $o->cylinder_simple(2, 3))->generate,
    "intersection(){
  cylinder(h=1, r=2, center=false);
  cylinder(h=2, r=3, center=false);
}");


is($o->intersection(
       $o->intersection(
           $o->cylinder_simple(1, 2),
           $o->cylinder_simple(1, 3)),
       $o->cylinder_simple(2, 3))->generate,
   "intersection(){
  intersection(){
    cylinder(h=1, r=2, center=false);
    cylinder(h=1, r=3, center=false);
  }
  cylinder(h=2, r=3, center=false);
}");

is($o->translate(-1, 0, 1,
                 $o->cylinder_simple(1, 2))->generate,
   "translate([-1, 0, 1])
  cylinder(h=1, r=2, center=false);");
