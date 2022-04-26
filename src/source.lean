-- https://cr.yp.to/papers/goppadecoding-20220320.pdf
import tactic
import data.polynomial.basic
import linear_algebra.matrix.nondegenerate
import linear_algebra.vandermonde
import data.matrix.basic
import data.polynomial.derivative
import logic.equiv.basic
import linear_algebra.lagrange
import algebra.order.monoid
import data.matrix.rank
import linear_algebra.finite_dimensional
import .with_bot

namespace polynomial
open_locale polynomial big_operators
open with_bot

noncomputable def degree_lt_equiv' (R : Type*) [comm_ring R] (n : ℕ)
: degree_lt R n ≃ₗ[R] (fin n → R) :=
{ to_fun := λ p n, (↑p : R[X]).coeff n,
  inv_fun := λ f, ⟨∑ i : fin n, monomial i (f i),
    (degree_lt R n).sum_mem (λ i _, mem_degree_lt.mpr (lt_of_le_of_lt
      (degree_monomial_le i (f i)) (with_bot.coe_lt_coe.mpr i.is_lt)))⟩,
  map_add' := λ p q, by { ext, rw [submodule.coe_add, coeff_add], refl },
  map_smul' := λ x p, by { ext, rw [submodule.coe_smul, coeff_smul], refl },
  left_inv :=
  begin
    rintro ⟨p, hp⟩, ext1,
    simp only [submodule.coe_mk],
    by_cases hp0 : p = 0,
    { subst hp0, simp only [coeff_zero, linear_map.map_zero, finset.sum_const_zero] },
    rw [mem_degree_lt, degree_eq_nat_degree hp0, with_bot.coe_lt_coe] at hp,
    conv_rhs { rw [p.as_sum_range' n hp, ← fin.sum_univ_eq_sum_range] },
  end,
  right_inv :=
  begin
    intro f, ext i,
    simp only [finset_sum_coeff, submodule.coe_mk],
    rw [finset.sum_eq_single i, coeff_monomial, if_pos rfl],
    { rintro j - hji, rw [coeff_monomial, if_neg], rwa [← subtype.ext_iff] },
    { intro h, exact (h (finset.mem_univ _)).elim }
  end }

theorem degree_lt_equiv_eq_iff {R : Type*} [comm_ring R] {n : ℕ} {p q : R[X]}
(h₀ : p ∈ degree_lt R n) (h₁ : q ∈ degree_lt R n) : degree_lt_equiv' _ _ ⟨_, h₀⟩ = degree_lt_equiv' _ _ ⟨_, h₁⟩ ↔ p = q :=
by { rw (linear_equiv.injective _).eq_iff, exact subtype.mk_eq_mk }

theorem degree_lt_equiv_eq_zero_iff {R : Type*} [comm_ring R] {n : ℕ} {p : R[X]}
(h : p ∈ degree_lt R n) : degree_lt_equiv' _ _ ⟨_, h⟩ = 0 ↔ p = 0 :=
by { rw linear_equiv.map_eq_zero_iff, apply submodule.mk_eq_zero, }

theorem degree_lt_equiv_apply {R : Type*} [comm_ring R] {n : ℕ} {p : R[X]}
(h : p ∈ degree_lt R n) (i : fin n) : degree_lt_equiv' _ _ ⟨_, h⟩ i = p.coeff i := rfl

theorem degree_lt_equiv_eval {R : Type*} [comm_ring R] {n : ℕ} {p : R[X]}
(h : p ∈ degree_lt R n) (x : R) :
∑ i, degree_lt_equiv' _ _ ⟨_, h⟩ i * (x ^ (i : ℕ)) = p.eval x :=
begin
  simp_rw [degree_lt_equiv_apply h, eval_eq_sum],
  exact sum_fin (λ e a, a * x ^ e) (λ i, zero_mul (x ^ i)) (mem_degree_lt.mp h)
end

theorem degree_lt_root {R : Type*} [comm_ring R] {n : ℕ} {p : R[X]}
(h : p ∈ degree_lt R n) (x : R) : p.is_root x ↔
∑ i, degree_lt_equiv' _ _ ⟨_, h⟩ i * (x ^ (i : ℕ)) = 0
:= by rw [is_root.def, degree_lt_equiv_eval h]

theorem mul_sub_mul_degree_lt_add_of_degrees_le_lt_le_lt {R : Type*} [comm_ring R] [no_zero_divisors R] {a b A B : R[X]} {n t : ℕ}
(hA : A.degree ≤ n) (hB : B.degree < n) (ha : a.degree ≤ t) (hb : b.degree < t)
: (a*B - b*A).degree < t + n := 
begin
  have h : (a * B - b * A).degree ≤ max (a.degree + B.degree) (b.degree + A.degree),
    exact le_trans (degree_sub_le _ _) (le_of_eq (by simp only [degree_mul])),
  rw [le_max_iff] at h, cases h; apply lt_of_le_of_lt h,
  exact add_lt_add_of_le_of_lt_of_right_ne_bot (coe_ne_bot _) ha hB,
  exact add_lt_add_of_lt_of_le_of_right_ne_bot (coe_ne_bot _) hb hA
end

/-
theorem degree_lt_rank {F : Type*} [field F] {t : ℕ} : module.rank F (degree_lt F t) = t := by {rw (degree_lt_equiv' F t).dim_eq, exact dim_fin_fun _}

theorem degree_lt_finrank {F : Type*} [field F] {t : ℕ} : finite_dimensional.finrank F (degree_lt F t) = t := finite_dimensional.finrank_eq_of_dim_eq degree_lt_rank
-/

end polynomial

section restrict
namespace linear_map
variables {R : Type*} {R₂ : Type*} {M : Type*} {M₂ : Type*} [semiring R] [semiring R₂] 
[add_comm_monoid M] [add_comm_monoid M₂] [module R M] [module R₂ M₂] {σ₁₂ : R →+* R₂}
(f : M →ₛₗ[σ₁₂] M₂) {p₁ : submodule R M} {p₂ : submodule R₂ M₂} (hf : p₁ ≤ submodule.comap f p₂) 

def restrict' : p₁ →ₛₗ[σ₁₂] p₂ := (f.dom_restrict _).cod_restrict _ (λ x, hf x.2)

lemma restrict_apply' (x : p₁) : (f.restrict' hf) x = ⟨f x, hf x.2⟩ := rfl

lemma restrict_eq_cod_restrict_dom_restrict' :
  f.restrict' hf = (f.dom_restrict p₁).cod_restrict p₂ (λ x, hf x.2) := rfl

lemma restrict_eq_dom_restrict_cod_restrict' (hf : ∀ x, x ∈ submodule.comap f p₂) :
  f.restrict' (λ x _, hf x) = (f.cod_restrict p₂ hf).dom_restrict p₁ := rfl

lemma ker_restrict' : (f.restrict' hf).ker = f.ker.comap p₁.subtype :=
by {ext, simp only [restrict_apply', mem_ker, submodule.mk_eq_zero,
                    submodule.mem_comap, submodule.coe_subtype]}

lemma range_restrict' [ring_hom_surjective σ₁₂] : (f.restrict' hf).range = (p₁.map f).comap p₂.subtype :=
begin
  ext y, simp only [ restrict_apply', mem_range, submodule.mem_comap,
                    submodule.coe_subtype, submodule.mem_map], split,
    rintro ⟨⟨x, hx⟩, rfl⟩, exact ⟨x, hx, rfl⟩,
    rintro ⟨x, ⟨hx, hy⟩⟩, refine ⟨⟨x, hx⟩, _⟩, simp_rw [submodule.coe_mk, hy, set_like.eta]
end
variables {p₁' : submodule R p₁} {p₂' : submodule R₂ p₂} 


lemma map_restrict' [ring_hom_surjective σ₁₂] : p₁'.map (f.restrict' hf) = (p₁'.map (f.comp p₁.subtype)).comap p₂.subtype :=
begin
  ext y, simp [restrict_apply'], split,
  rintro ⟨x, hx, rfl⟩, exact ⟨x, hx, rfl⟩,
  rintro ⟨x, hx, hy⟩, refine ⟨x, hx, _⟩, simp_rw [hy, set_like.eta]
end


lemma comap_restrict' : p₂'.comap (f.restrict' hf) = (p₂'.map p₂.subtype).comap (f.comp p₁.subtype) :=
begin
  ext y, simp [restrict_apply'],
end

end linear_map
end restrict

section comap

section monoid_monoid

variables {R : Type*} {R₂ : Type*} {M : Type*} {M₂ : Type*} [semiring R] [semiring R₂]
[add_comm_monoid M] [add_comm_monoid M₂] [module R M] [module R₂ M₂] {τ₁₂ : R →+* R₂}
(f : M →ₛₗ[τ₁₂] M₂) {p : submodule R M} {q q' : submodule R₂ M₂} 
open submodule

namespace linear_map
lemma ker_eq_comap : f.ker = comap f ⊥ := rfl

lemma ker_le_comap {f : M →ₛₗ[τ₁₂] M₂} : f.ker ≤ comap f q := comap_mono bot_le

variable [ring_hom_surjective τ₁₂] 

lemma comap_range : comap f (f.range) = ⊤ := eq_top_iff'.mpr (λ _, ⟨_, rfl⟩)

lemma comap_eq_comap_range_inf : comap f q = comap f (f.range ⊓ q) :=
by rw [comap_inf, comap_range, top_inf_eq]

lemma comap_le_comap_iff' : comap f q ≤ comap f q' ↔
f.range ⊓ q ≤ q' := by rw [← map_le_iff_le_comap, map_comap_eq]

lemma comap_le_ker_iff : comap f q ≤ f.ker ↔ f.range ⊓ q = ⊥ :=
by rw [ker_eq_comap, comap_le_comap_iff', le_bot_iff]
end linear_map

open linear_map
variable [ring_hom_surjective τ₁₂]

lemma submodule.comap_eq_ker_iff : comap f q = f.ker ↔ f.range ⊓ q = ⊥ :=
⟨ λ h, (comap_le_ker_iff _).mp (le_of_eq h),
  λ h, le_antisymm ((comap_le_ker_iff _).mpr h) ker_le_comap⟩

lemma submodule.map_ker : submodule.map f (f.ker) = ⊥ := (submodule.eq_bot_iff _).mpr
(by simp only [ mem_map, mem_ker, forall_exists_index, and_imp,
                forall_apply_eq_imp_iff₂, imp_self, forall_const])

lemma submodule.map_eq_map_sup_ker : submodule.map f p = submodule.map f (p ⊔ f.ker) :=
by rw [map_sup, submodule.map_ker, sup_bot_eq]


end monoid_monoid
section group_monoid
open submodule
variables {R : Type*} {R₂ : Type*} {M : Type*} {M₂ : Type*} [ring R] 
[add_comm_group M] [add_comm_group M₂] [module R M] [module R M₂] 
(f : M →ₗ[R] M₂) {p : submodule R M} {q : submodule R M₂}
{p' : submodule R p} {q' : submodule R q} 
(hf : p ≤ q.comap f) --Might not need hf?

def submodule.quotient_ker_equiv_map : 
(_ ⧸ (p ⊓ f.ker).comap p.subtype) ≃ₗ[R] p.map f := sorry
-- And, consequently, rank p = rank p.map f + rank (p ⊓ f.ker).

def submodule.quotient_range_equiv_quotient_comap :
(_ ⧸ q.comap (f.range ⊔ q).subtype) ≃ₗ[R] M ⧸ q.comap f := sorry
-- And, consequently, rank f.range ⊔ q + rank q.comap f = rank M + rank q, which 
-- you can also read as: corank q = corank q.comap f + corank (f.range ⊔ q)

-- We use a restricted version of f for submodules of the submodules.

def submodule.quotient_ker_equiv_map' :
(_ ⧸ (p' ⊓ f.ker.comap p.subtype).comap p'.subtype) ≃ₗ[R] p'.map (f.restrict' hf) := sorry

def submodule.quotient_range_equiv_quotient_comap' :
(_ ⧸ q'.comap ((p.map f).comap q.subtype ⊔ q').subtype) ≃ₗ[R] _ ⧸ q'.comap (f.restrict' hf) := sorry



end group_monoid
section cokernel



variables {R : Type*} {R₂ : Type*} {M : Type*} {M₂ : Type*} [ring R] [ring R₂]
[add_comm_group M] [add_comm_group M₂] [module R M] [module R₂ M₂] {τ₁₂ : R →+* R₂}
(f : M →ₛₗ[τ₁₂] M₂) {p p' : submodule R M} [ring_hom_surjective τ₁₂]

def linear_map.coker : module R₂ (M₂ ⧸ f.range) := submodule.quotient.module _
noncomputable def corank := module.rank R₂ (M₂ ⧸ f.range)

def linear_map.corange : module R (M ⧸ f.ker) := submodule.quotient.module _

protected noncomputable def submodule.corank := module.rank R (M ⧸ p) 

end cokernel

section group
variables {R : Type*} {R₂ : Type*} {M : Type*} {M₂ : Type*} [semiring R] [semiring R₂]
[add_comm_group M] [add_comm_group M₂] [module R M] [module R₂ M₂] {τ₁₂ : R →+* R₂}
(f : M →ₛₗ[τ₁₂] M₂) {p p' : submodule R M} [ring_hom_surjective τ₁₂]

lemma range_le_map_iff : f.range ≤ submodule.map f p ↔ p ⊔ f.ker = ⊤ :=
by rw [range_eq_map, linear_map.map_le_map_iff, top_le_iff]

lemma range_eq_map_iff : f.range = submodule.map f p ↔ p ⊔ f.ker = ⊤ :=
⟨ λ h, (range_le_map_iff _).mp (le_of_eq h),
  λ h, le_antisymm ((range_le_map_iff _).mpr h) map_le_range⟩

-- map_eq_top_iff is just a special case of this.

-- comap_map_eq and comap_map_eq_self are in the wrong file (should be in basic).

end group

end comap
end linear_map

namespace submodule

variables {R : Type*} {M : Type*} {M' : Type*} [semiring R]
[add_comm_monoid M] [add_comm_monoid M'] [module R M] [module R M']
(p : submodule R M) (q : submodule R M')

def prod_equiv : p.prod q ≃ₗ[R] p × q :=
{ map_add' := λ x y, rfl, map_smul' := λ x y, rfl, .. equiv.set.prod ↑p ↑q }

-- On some level, this is probably a theorem about coranks and the dimension of comap. But I don't 
-- understand that, so let's not worry about it. I suspect it can be generalised.
open linear_map


theorem comap_nontrivial {K : Type*} {V : Type*} [field K] [add_comm_group V] [module K V] {V₂ : Type*} [add_comm_group V₂] [module K V₂] 
(f : V →ₗ[K] V₂) {q : submodule K V₂} (h : (module.rank K V₂) < (module.rank K q) + (module.rank K V) )
: comap f q ≠ ⊥ :=
begin
  intro H, 
  --submodule.disjoint_iff_comap_eq_bot
  /-have range_inf_zero : disjoint f.range p,
  { rw submodule.disjoint_iff_comap_eq_bot,
    
    simp_rw [submodule.eq_bot_iff, submodule.mem_comap],
    intros _ ha,
    apply H _ ha,
    simp only [ mem_inf, mem_range, and_imp,
                forall_exists_index, forall_apply_eq_imp_iff'],
    intros _ ha,
    rw [H _ ha, f.map_zero]
  },-/
  apply not_le_of_lt h,
  have j := congr_arg ((+) (module.rank K ↥q)) (dim_range_add_dim_ker f),
  rw ← add_assoc at j,
  rw ← _root_.dim_sup_add_dim_inf_eq at j,
  have jj := congr_arg (λ x, x + (module.rank K (comap f q))) j,
  simp at jj,
  clear j,
  rw add_assoc at jj,
  rw ← @_root_.dim_sup_add_dim_inf_eq _ V at jj,
  rw [  ←finrank_range_of_inj (ker_zero), ← submodule.dim_sup_add_dim_inf_eq],
  apply submodule.finrank_le,
end

end submodule


-- Section 2 (Polynomials)
/-
Much of this section is straightforwardly in mathlib. Imports are given (though
some may be redundant), and where there is a wrinkle to do with the way Lean
represents things, it's noted.
-/
section gdtwo

-- 2.1 (Commutative rings)
/-
Provided by the comm_ring structure. Note that there is a theory of semirings,
not-necessarily-commutative rings, etc. also.

import algebra.ring.basic
-/

-- 2.2 Ring morphisms
/-
Provided by the ring_hom structure (which extends multiplicative and additive 
homomorphisms). This gives additive and multiplicative identity preservation,
and distribution over the operations. Preservation of additive inverse is given
by ring_hom.map_neg.

import algebra.ring.basic
-/

-- 2.3 Multiples
/-
This is simply about ideals and their generators. This is probably best given by
ideal.span (which defines the ideal which is generated by a ring). There are a
collection of span_singleton lemmas for the special case where the generating
set is a singleton (a principal ideal). There is a theorem of principal ideal
domains but this seems not necessary here.

import ring_theory.ideal.basic
-/

-- 2.4 Units
/-
The definition of a (multiplicative) unit is given by the is_unit predicate.
units M is the structure which contains the units of a monoid M in a bundled way
(that is, something of type units M contains the unit, its inverse, and proofs
that they form a left-sided and right-sided unit pair). units M is not a set - 
you cannot talk about a ∈ units M, but given some a : M (where we have [ring M]),
if you have a hypothesis of type is_unit a, that contains the u : units M whose
coercion is a, so you can extract it. 

import algebra.group.units
-/

-- 2.5 Fields
/-
Given by the field structure. The is_field predicate expresses that a ring is a
field; the is_field.to_field definition noncomputably takes a proof that a 
ring R is a field and gives the field structure resulting.

import algebra.field.basic

-/

-- 2.6 Vector space
/-
A vector space is a module over a field. Lean does not have a separate notion of
a vector space, and so the module structure (which corresponds to a semimodule
in regular maths - i.e. it can be defined over a semiring) is used for it.

There is a lot of subtlety here that is not relevant outside of the original 
algebraic context, and so other imports might be needed. Handle with care.

import algebra.module.basic
-/

-- 2.7 Standard n-dimensional vector space.
/-
A complicated issue because in full generality these structure can have
complicated indexing and so much is given in a high level of abstraction.
On top of that, finiteness can be a tricky issue when trying to do stuff
correctly. It might be that actually want you want is matrix.std_basis
or matrix.std_basis_matrix, as this could give you the matrix basis for the
special case of rows and columns. You need to think carefully about what is
meant here.

If you just want row vectors, incidentally, the ![a, b, ..., z] notation
introduced by data.fin.vec_notation will suffice, as these are things to which
matrices can be applied.

The following should give the required notation and the basis stuff. But here
be dragons if you aren't careful.

import data.matrix.basis
import data.matrix.notation
-/

-- 2.8 Linear maps
/-
The linear_map structure of algebra.module.linear_map is the abstract version of
this.

finrank_le_finrank_of_injective is the theorem that if a linear map between
two finite-dimensional spaces is injective, the dimension of the domain
is less than or equal to the dimension of the codomain. The converse implies
that when the domain has a greater dimension than the codomain, there is some
non-zero vector which maps to zero. One can also look at this using the
rank-nullity theorem, finrank_range_add_finrank_ker.

The theory of finite-dimensional spaces is obviously full of particular
theorems, and is covered by linear_algebra.finite_dimensional.

import algebra.module.linear_map
import linear_algebra.finite_dimensional
-/

-- 2.9 Polynomials
/-
Polynomials over a ring R are really just finitely-supported maps from R to
ℕ, along with the structure that retains the structure of R for addition and
scalar multiplication and defines products using convolution. This is an
additive monoid algebra, and so secretly this is just what a polynomial is
in Lean. However, data.basic provides a good API and notation so that
we mostly don't have to worry about any of this.

Note that polynomials are not (currently) implemented in a computable way -
that is, the definition of polynomials is sufficiently abstracted that it
requires classical choice. This might change at some point (because it is
not ideal...)

import data.polynomial.basic

-/

-- 2.10 The ring-structure of polynomials
/-
As mentioned, the commutative ring structure on polynomials over a commutative
ring is virtually present by definition. semiring is the core
instance - there are various other instances for generalisations or different
ways to view the structure.
-/

-- 2.11 The k-algebra structure of polynomials
/-
The C map is the constant map from R to R[X]. This is the algebra 
map. The instance algebra_of_algebra shows that A[X] is an R-algebra
when A is an R-algebra, which gives the special case when A = R, and API is
provided for working with this.

import data.algebra_map
-/

-- 2.12 Units of k[x]
/-
The theorem is_unit_iff characterises the units of R[X], where R is 
commutative domain, as the embedding of the units of R. When R is not a domain
but simply a commutative semiring, it is still true that a member of R is a unit
iff its embedding is (is_unit_C). (Consider (2X + 1)*(2X + 1) when R
is Z/(4) - 2X + 1 is a unit without degree 0. The issue turns out to be that
deg(f*g) = deg f * deg g for non-zero f, g may not be true in the presence of
zero divisors.)

import data.polynomial.ring_division
-/

-- 2.13 The k-vector structure of polynomials
/-
We have module as an instance, and it's definitionally equal to the
instance of module that arises from the instance of polynomials as an algebra
under the base ring - so from Lean's point of view these are the same.

import data.polynomial.basic
-/

-- 2.14 Powers of x
/-
monomial n a is the monomial a*X^n. We have sum_monomial_eq which tells us that
a polynomial is equal to the sum over its coefficients f_i of f_i*X^i (Lean
provides sum to do this kind of summation: internally this is a 
finset.sum. This is as opposed to a finsum, which is the infinite sum over
finite non-zero values mentioned in the paper: for various reasons there are a
few different ways of doing finite sums but this is the way polynomial does 
things). We also have from this a way of doing induction on polynomials by 
proving an additive fact for monomials.

import data.polynomial.induction

-/

-- 2.15 Coefficients
/-
coeff p n gives the nth coefficient of n in p, where n : ℕ. Extending
this to ℤ would not be too hard; what the appropriate decision in 4.1 would
be is yet to be answered.

import data.polynomial.basic
-/

-- 2.16 Degree
/-
We have both degree and nat_degree (which differ in how
they handle the zero polynomial). There are a good number of theorems for these.

import data.polynomial.basic
-/


-- 2.17 Monic polynomials
/-
There is a monic predicate.

import data.degree.definitions
-/

-- 2.18 Evaluation
/-
eval exists, though it is non-computable so you can prove theorems
about it but not actually evaluate computationally.

import data.polynomial.basic
-/
-- 2.19 Roots
/-
roots gives a multiset of the polynomial's roots,
including multiplicity. It does not have a meaningful definition for the zero
polynomial!

import data.polynomial.basic
-/
-- 2.20 Vandermonde invertibility
/-
This derives from card_roots, which is a version of it though not
in the equivalent form.

However, it is also true separately from polynomial theory.
-/

-- 2.21 Transposed Vandermonde inequality
/-
Easily proved.
-/
open finset
open_locale big_operators classical polynomial matrix

namespace matrix
lemma det_vandermonde_ne_zero_of_injective {R : Type*} [comm_ring R] 
[is_domain R] {n : ℕ} (α : fin n ↪ R) : (vandermonde α).det ≠ 0 :=
begin
  simp_rw [det_vandermonde, prod_ne_zero_iff, mem_filter, 
  mem_univ, forall_true_left, true_and, sub_ne_zero, ne.def, 
  embedding_like.apply_eq_iff_eq],
  rintro _ _ _ rfl, apply lt_irrefl _ (by assumption)
end

theorem vandermonde_invertibility' {R : Type*} [comm_ring R]
[is_domain R] {n : ℕ} (α : fin n ↪ R) {f : fin n → R}
(h₂ : ∀ j, ∑ i : fin n, (α j ^ (i : ℕ)) * f i = 0) : f = 0
:= by {apply eq_zero_of_mul_vec_eq_zero (det_vandermonde_ne_zero_of_injective α), ext, apply h₂}

theorem vandermonde_invertibility {R : Type*} [comm_ring R]
[is_domain R] {n : ℕ}
{α : fin n ↪ R} {f : fin n → R}
(h₂ : ∀ j, ∑ i, f i * (α j ^ (i : ℕ))  = 0) : f = 0
:= by {apply vandermonde_invertibility' α, simp_rw mul_comm, exact h₂}

theorem vandermonde_invertibility_transposed {R : Type*} [comm_ring R] 
[is_domain R] {n : ℕ}
{α : fin n ↪ R} {f : fin n → R}
(h₂ : ∀ i : fin n, ∑ j : fin n, f j * (α j ^ (i : ℕ)) = 0) : f = 0
:= by {apply eq_zero_of_vec_mul_eq_zero 
(det_vandermonde_ne_zero_of_injective α), ext, apply h₂}

end matrix

namespace polynomial
open linear_equiv matrix



theorem vandermonde_invertibility {R : Type*} [comm_ring R] [is_domain R] {n : ℕ}
(α : fin n ↪ R) {p : R[X]} (h₀ : p ∈ degree_lt R n) (h₁ : ∀ j, p.is_root (α j)) : p = 0 :=
begin
  simp_rw degree_lt_root h₀ at h₁,
  exact (degree_lt_equiv_eq_zero_iff h₀).mp (vandermonde_invertibility h₁)
end

theorem vandermonde_invertibility_tranposed {R : Type*} [comm_ring R] [is_domain R]
{n : ℕ} (α : fin n ↪ R) {p : R[X]} (h₀ : p ∈ degree_lt R n)
(h₁ : ∀ i : fin n, ∑ j : fin n, p.coeff j * (α j ^ (i : ℕ)) = 0) : p = 0 :=
(degree_lt_equiv_eq_zero_iff h₀).mp (vandermonde_invertibility_transposed h₁)

theorem vandermonde_agreement {R : Type*} [comm_ring R] [is_domain R] {n : ℕ}
(α : fin n ↪ R) {p q : R[X]} (h₀ : (p - q) ∈ degree_lt R n)
(h₂ : ∀ j, p.eval (α j) = q.eval (α j)) : p = q :=
begin
  rw ← sub_eq_zero, apply vandermonde_invertibility α h₀,
  simp_rw [is_root.def, eval_sub, sub_eq_zero], exact h₂
end

-- 2.22 Derivatives
/-
derivative is the formal derivative of a  The product 
rule is proven for it. Bernoulli's rule is not proven for it, but this shouldn't
be too difficult.

import data.derivative
-/

theorem bernoulli_rule {R : Type*} [comm_ring R]  {p q : R[X]} {x : R} (h : p.is_root x) : (p*q).derivative.eval x = p.derivative.eval x * q.eval x :=
begin
  rw is_root.def at h,
  simp only [is_root.def, h, derivative_mul, eval_add, eval_mul, zero_mul, add_zero]
end 
end polynomial
-- 2.23 Quotients and remainders
/-
There is a notion of polynomial division and modulo, but also polynomial
is a Euclidean domain which gives the q/r decomposition.
-/
-- 2.24 Unique Factorisation
/-
We have an instance of unique_factorization_monoid for polynomial, and it follows
from the Euclidean domain stuff.

-/
-- 2.25 Greatest common divisors
/-
Follows from Euclidean domain.
-/

-- 2.26 Squarefreeness
/-
separable.squarefree precisely gives that a polynomial is squarefree
if it is separable - which is exactly that it is coprime with its formal derivative.

import field_theory.separable
-/

end gdtwo

/-

namespace polynomial

universes u y v

variables {R : Type u} [comm_semiring R] {ι : Type y}

open_locale polynomial classical big_operators

theorem derivative_prod' {s : finset ι} {f : ι → R[X]} :
  derivative (∏ b in s, f b) = ∑ b in s, (∏ a in (s.erase b), f a) * (f b).derivative := derivative_prod

end polynomial
-/

section gdthree
open_locale polynomial classical big_operators



noncomputable theory

open polynomial finset

universes u v

def nodal {F : Type u} [field F] (s : finset F) : F[X] := ∏ y in s, (X - C y)

lemma nodal_eq_remove {F : Type u} [field F] {s : finset F} {x : F} (hx : x ∈ s) : nodal s = (X - C x) * (∏ y in s.erase x, (X - C y)) := by {rw mul_prod_erase _ _ hx, refl}

lemma nodal_derive_eval_node_eq {F : Type u} [field F] {s : finset F} {x : F} (hx : x ∈ s) : eval x (nodal s).derivative = ∏ y in (s.erase x), (x - y) := 
begin
  rw [nodal_eq_remove hx, bernoulli_rule (root_X_sub_C.mpr rfl)],
  simp_rw [eval_prod, derivative_sub, derivative_X, derivative_C, sub_zero, eval_one, one_mul, eval_sub, eval_X, eval_C]
end

lemma nodal_div_eq {F : Type u} [field F] {s : finset F} {x : F} (hx : x ∈ s) :
nodal s / (X - C x) = (∏ y in s.erase x, (X - C y)) := 
begin
  rw [nodal_eq_remove hx, euclidean_domain.mul_div_cancel_left],
  apply X_sub_C_ne_zero,
end

lemma lagrange.basis_eq_nodal_div_eval_deriv_mul_linear {F : Type u} [field F] {s : finset F} {x : F} (hx : x ∈ s) : lagrange.basis s x = C (eval x (nodal s).derivative)⁻¹ * (nodal s / (X - C x))  :=
begin
  unfold lagrange.basis,
  rw [nodal_div_eq hx, nodal_derive_eval_node_eq hx, prod_mul_distrib, ← prod_inv_distrib', map_prod],
end

lemma interpolate_eq_derivative_interpolate {F : Type u} [field F] (s : finset F) (f : F → F) : lagrange.interpolate s f = ∑ x in s, C (f x * (eval x (nodal s).derivative)⁻¹) * (nodal s / (X - C x)) :=
begin
  apply sum_congr rfl, intros _ hx,
  rw [C.map_mul, lagrange.basis_eq_nodal_div_eval_deriv_mul_linear hx, mul_assoc]
end

end gdthree

section gdfour
open_locale classical polynomial 

open polynomial linear_map algebra

def approximant_error {R : Type*} [comm_ring R] (A B : R[X]) : R[X] × R[X] →ₗ[R] R[X] := 
coprod (lmul_right _ B) (lmul_right _ (-A))

def approximant_quotient {R : Type*} [comm_ring R] {a b A B : R[X]}
{n : ℕ} (hA : A ∈ degree_le R n) (hB : B ∈ degree_lt R n)
{t : ℕ} (ha : a ∈ degree_le R t) (hb : b ∈ degree_lt R t) : 
R[X] × R[X] →ₗ[R] R[X] ⧸ degree_lt R (n - t) := 
(degree_lt R (n - t)).mkq.comp (approximant_error A B)

lemma approximant_error_apply {R : Type*} [comm_ring R] {A B a b : R[X]} : approximant_error A B (a, b) = a*B - b*A := by {simp only [approximant_error, coprod_apply, lmul_right_apply], ring }

theorem approximate_error_bounded_degree
{R : Type*} [comm_ring R] [no_zero_divisors R] {A B : R[X]}
{n : ℕ} (hA : A ∈ degree_le R n) (hB : B ∈ degree_lt R n) (t : ℕ) :
∀ ab : R[X] × R[X], ab ∈ (degree_le R t).prod (degree_lt R t) →
(approximant_error A B) ab ∈ degree_lt R (t + n) := 
begin
  simp only [ mem_degree_lt, mem_degree_le, approximant_error_apply,
              submodule.mem_prod, and_imp, prod.forall] at *,
  intros a b ha hb,
  exact mul_sub_mul_degree_lt_add_of_degrees_le_lt_le_lt hA hB ha hb
end

def approximant_error_restricted {R : Type*} [comm_ring R] [no_zero_divisors R] {A B : R[X]}
{n : ℕ} (hA : A ∈ degree_le R n) (hB : B ∈ degree_lt R n) (t : ℕ) :
(degree_le R t).prod (degree_lt R t) →ₗ[R] degree_lt R (t + n) :=
linear_map.restrict' _ (approximate_error_bounded_degree hA hB _)


end gdfour