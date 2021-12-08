import topology.basic
import topology.metric_space.basic
import topology.path_connected
import topology.continuous_function.basic
import topology.homotopy.basic
import topology.homotopy.fundamental_groupoid
import category_theory.endomorphism
import category_theory.groupoid
import algebra.category.Group.basic
import category_theory.category.basic
import category_theory.types
import .pointed_space

/--
Define the fundamental group as the the automorphism group of the fundamental groupoid i.e.
the set of all arrows from the basepoint to itself (p ⟶ p).
-/
def fundamental_group {X : Type} [topological_space X] (Xp : pointed_space X) : Type :=
@category_theory.Aut
  X
  (@category_theory.groupoid.to_category (fundamental_groupoid X) _)
  Xp.basepoint

/--
Use the automorphism group instance to give a group structure to the fundamental group.
-/
noncomputable instance fundamental_group.group {X : Type} [topological_space X] {Xp : pointed_space X} :
   group (fundamental_group Xp) :=
@category_theory.Aut.group
  X
  (@category_theory.groupoid.to_category (fundamental_groupoid X) _)
  Xp.basepoint

noncomputable instance category_struct.topological_space {X : Type} [topological_space X] : category_theory.category_struct X :=
fundamental_groupoid.category_theory.groupoid.to_category_struct

-- noncomputable instance fundamental_group.mul_one_class {X : Type} [topological_space X] {Xp : pointed_space X} :
--   mul_one_class (fundamental_group Xp) := {
--   one := fundamental_group.group.one,
--   mul := fundamental_group.group.mul,
--   one_mul := fundamental_group.group.one_mul,
--   mul_one := fundamental_group.group.mul_one,
-- }

@[simp]
def space_of_fg {X : Type} [topological_space X] (p : fundamental_groupoid X) : X := p
notation `↓` p : 70 := space_of_fg p

/--
Type alias for working with loops in a space X with basepoint p.
-/
def loop {X : Type} [topological_space X] (Xp : pointed_space X) : Type :=
path Xp.basepoint Xp.basepoint

example (X Y : Type) (f : X → Y) (a b : X) : a = b → f a = f b :=
begin
  exact congr_arg (λ (a : X), f a),
end

/--
Defines the homotopy between an out-and-back path and a point i.e. for path γ
starting at point p, γ * γ⁻¹ ∼ p.
-/
noncomputable def linear_symm_homotopy {X : Type} [topological_space X] {p q : X} (γ : path p q) :
  path.homotopy (path.refl p) (γ.trans γ.symm) := {
  to_homotopy := {
    to_fun := λst, γ (subtype.mk (st.fst.val * (1 - |1 - 2 * st.snd.val|)) sorry),
    to_fun_zero := by simp,
    to_fun_one := begin
      simp,
      intros t ht,
      rw path.trans_apply,
      split_ifs; simp [unit_interval.symm]; apply congr_arg,
      sorry,
      sorry,
    end,
  },
  prop' := begin
    intros s t ht,
    simp,
    apply and.intro,
    { sorry, },
    { sorry, },
  end,
}

/--
Given a path connected space X and two points p, q, we return a path between them
along with the reverse path, bundled together.
-/
noncomputable def conn_path {X : Type} [topological_space X] [path_connected_space X] (p q : X) :
  @category_theory.iso (fundamental_groupoid X) _ p q :=
let pq_path := joined.some_path (path_connected_space.joined p q) in {
  hom := @quotient.mk (path p q) (path.homotopic.setoid p q) pq_path,
  inv := @quotient.mk (path q p) (path.homotopic.setoid q p) pq_path.symm,
  hom_inv_id' := begin
    apply quotient.sound,
    apply nonempty_of_exists,
    apply @exists.intro _ (λ_, true)
      (path.homotopy.symm (linear_symm_homotopy pq_path))
      (by tautology),
  end,
  inv_hom_id' := begin
    apply quotient.sound,
    apply nonempty_of_exists,
    let homotopy := linear_symm_homotopy pq_path.symm,
    rw path.symm_symm at homotopy,
    apply @exists.intro _ (λ_, true)
      (path.homotopy.symm homotopy)
      (by tautology),
  end,
}

/--
Given a path connected space X, the fundamental group is independent of which basepoint was used.
-/
noncomputable theorem iso_fg_of_path_conn {X : Type} [topological_space X] [path_connected_space X]
  (Xp : pointed_space X) (Xq : pointed_space X) :
  (fundamental_group Xp) ≅ (fundamental_group Xq) :=
let α := conn_path Xp.basepoint Xq.basepoint in {
  hom := λγ, category_theory.iso.mk
    (α.inv ≫ γ.hom ≫ α.hom)
    (α.inv ≫ γ.inv ≫ α.hom)
    (by simp)
    (by simp),
  inv := λγ, category_theory.iso.mk
    (α.hom ≫ γ.hom ≫ α.inv)
    (α.hom ≫ γ.inv ≫ α.inv)
    (by simp)
    (by simp),
}

/--
Given a continuous function between pointed spaces, we can create a functor between the
associated fundamental groupoids of the spaces.
-/
noncomputable def induced_groupoid_functor {X Y : Type} [topological_space X] [topological_space Y]
  {Xp : pointed_space X} {Yq : pointed_space Y} (f : Cp(Xp, Yq)) :
  fundamental_groupoid X ⥤ fundamental_groupoid Y := {
  obj := f,
  map := begin
    intros p₁ p₂ α,
    let x_setoid := path.homotopic.setoid (↓p₁) (↓p₂),
    let y_setoid := path.homotopic.setoid (f ↓p₁) (f ↓p₂),
    have h_cont : continuous ⇑f := f.to_continuous_map.continuous,

    let f_path : path (↓p₁) (↓p₂) → path (f ↓p₁) (f ↓p₂) :=
      λγ, {
        to_continuous_map := {
          to_fun := f ∘ γ,
          continuous_to_fun := begin
            apply continuous.comp,
            { exact continuous_map.continuous_to_fun f.to_continuous_map, },
            { exact continuous_map.continuous_to_fun γ.to_continuous_map, },
          end,
        },
        source' := by simp,
        target' := by simp,
      },
    let f_path_class : path (↓p₁) (↓p₂) → ((f p₁) ⟶ (f p₂)) :=
      λγ, @quotient.mk _ y_setoid (f_path γ),
    let f_lift : (p₁ ⟶ p₂) → ((f p₁) ⟶ (f p₂)) :=
      begin
        apply @quotient.lift _ _ x_setoid f_path_class,
        intros γ₁ γ₂ h_homotopic,
        apply quotient.sound,
        apply nonempty.intro,
        exact {
          to_homotopy := {
            to_fun := f ∘ ⇑(classical.choice h_homotopic),
            to_fun_zero := by simp,
            to_fun_one := by simp,
          },
          prop' := begin
            intros s t h,
            simp,
            sorry,
          end,
        },
      end,
    exact f_lift α,
  end,
}

notation `↟` f : 70 := induced_groupoid_functor f

@[simp]
lemma f_of_induced_groupoid_functor {X Y : Type} [topological_space X] [topological_space Y]
  {Xp : pointed_space X} {Yq : pointed_space Y} (f : Cp(Xp, Yq)) :
  (↟f).obj = f := by refl

/--
Given a function f : X → Y, returns the induced map between the fundamental groups i.e.
returns f⋆ : π₁(X) → π₁(Y).
-/
noncomputable def induced_hom {X Y : Type} [topological_space X] [topological_space Y]
  {Xp : pointed_space X} {Yq : pointed_space Y} (f : Cp(Xp, Yq)) :
  (fundamental_group Xp) →* (fundamental_group Yq) := {
  to_fun := λγ, {
    hom :=
      begin
        let δ := (↟f).map γ.hom,
        have h_pointed : f Xp.basepoint = Yq.basepoint := pointed_continuous_map.pointed_map f,
        -- rw f_of_induced_groupoid_functor at δ,
        -- rw h_pointed at δ,
        simp [induced_groupoid_functor, h_pointed] at δ,
        exact δ,
      end,
    inv :=
      begin
        let δ := (↟f).map γ.inv,
        have h_pointed : f Xp.basepoint = Yq.basepoint := pointed_continuous_map.pointed_map f,
        simp [induced_groupoid_functor, h_pointed] at δ,
        exact δ,
      end,
    hom_inv_id' := begin -- TODO: deal with the cast (get rid of it and the rest is trivial via simp)
      simp, sorry,
    end,
    inv_hom_id' := sorry,
  },
  map_one' := sorry,
  map_mul' := sorry,
}

/--
Given a surjective map f : X → Y, the induced map f⋆ on fundamental groups is also surjective.
-/
lemma surj_hom_of_surj {X Y : Type} [topological_space X] [topological_space Y]
  {Xp : pointed_space X} {Yq : pointed_space Y} (f : Cp(Xp, Yq)) :
  function.surjective f → function.surjective (induced_hom f) :=
sorry
