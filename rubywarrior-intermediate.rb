# @author janfrs
#
# My Idea was to create priorities of actions
# so the warrior could decide what was more important
# at that turn
class Player
  def play_turn(warrior)
    # cool code goes here
    # we could not set instance variables outside main loop
    @warrior = warrior 
    # DRYing mapping warrior proximities spaces
    @nearby_spaces = [
      @warrior.feel(:left),
      @warrior.feel(:right),
      @warrior.feel(:forward),
      @warrior.feel(:backward)
    ]
    
    #warrior actions decision priorities
    save :ticking or   # save captives trapped with ticking bombs is always more important
    survive or         # warrior needs to stay alive
    fight or           # warrior needs to fight to make more points
    chase or           # warrior's got to chase enemies to fight them
    save or            # after warrior's done with his enemies, save the other captives
    go_away            # nothing more to do, proceed to stairs
  end
  
  ############### WARRIOR DIRECTIVES #####################
  #                                                      #
  # Warrior's main actions declarations go here          #
  #                                                      #
  ########################################################
  
  # Warrior way of survival, it rests when it can:
  #       when is not being attacked;
  #       if it's being attacked and it is in danger step back
  #       to heal in safety;
  #       try to not get into more trouble while stepping back
  #       (eg. getting surrounded while running away... no good)
  def survive
    if @health == nil
      @health = @warrior.health
    end
    attacked = @warrior.health < @health
    @health = @warrior.health
    if not attacked and @warrior.health < 15
      @warrior.rest!
    elsif attacked and @warrior.health < 5 and not cornered?
      @warrior.walk!(
        @warrior.direction_of(empty_spaces_next.first)
      )
    else
      return false
    end
    return true
  end
  
  # Warrior's fighting
  #
  # When surrounded, bind enemies to make a fair fight;
  # If it can, throw a bomb;
  # if bombs are no good, attack with sword;
  def fight
    enemies = enemies_next
    if surrounded?
      @warrior.bind! @warrior.direction_of(enemies.first)
      return true
    elsif could_bomb
      detonate
      return true
    elsif enemies_next?
      @warrior.attack! @warrior.direction_of(enemies.first)
      return true
    else
      return false
    end
  end
  
  # when no enemies are around, go after the next enemy
  def chase
    enemies = find_enemies
    if not enemies.empty?
      @warrior.walk! @warrior.direction_of(enemies.first)
      return true
    end
    return false
  end
  
  # detonate a bomb if you can survive the damage!
  def detonate
    if @health > 4
      @warrior.detonate!
      return true
    end
    return false
  end
  
  
  # Warrior way to save captives
  #
  # @property ticking decide if you're saving ticking captives
  # sometimes warrior will not be able to save captive, so he
  # will pass the control to another function, to fight until
  # he can save the captives
  def save(ticking=nil)
    captives = find_captives(ticking)
    if not captives.empty?
      captive = captives.first #decides to go after the first captive
      direction = @warrior.direction_of captive
      next_step = @warrior.feel(direction)
      if next_step.captive?
        @warrior.rescue! direction
      elsif not next_step.empty? 
        if not surrounded? and not cornered?(direction)
          #warrior will try another direction to get to captive
          @warrior.walk!(
            @warrior.direction_of(empty_spaces_next(direction).first)
          )
        else
          return false
        end
      elsif not cornered?(direction)
        @warrior.walk! direction
      else
        return false
      end
      return true
    end
    return false
  end
  
  #Warrior action to go right to stairs
  def go_away
    stairs = @warrior.direction_of_stairs
    @warrior.walk! stairs
    return true
  end
  
  ############## enemy helper methods ###############
  #                                                 #
  # All about enemies                               #
  ###################################################
  
  #return array of enemies next to warrior
  def enemies_next
    enemies = []
    @nearby_spaces.each do |space|
      if space.enemy?
        enemies.push(space)
      end
    end
    return enemies
  end
  
  #return true if there are enemies next
  def enemies_next?
    return enemies_next.length > 0
  end
  
  #return array of all enemies
  def find_enemies
    enemies = []
    @warrior.listen.each do |space|
      if space.enemy?
        enemies.push(space)
      end
    end
    return enemies
  end
  
  #returns if you are surrounded
  def surrounded?
    return enemies_next.length > 1
  end
  
  #returns if warrior is cornered to only one space
  def cornered?(direction=nil)
    return empty_spaces_next(direction).length <= 1
  end
  
  
  ########## Misc Methods ##########################
  #                                                #
  # used throughout the code for many things       #
  ##################################################
  
  # return array of empty spaces next to warrior
  # @property direction - prioritize this direction
  # in case there are more than 1 space to go to
  def empty_spaces_next(direction=nil)
    priority_covered = false
    empty_spaces = []
    @nearby_spaces.each do |space|
      if space.empty?
        empty_spaces.push(space)
      end
      if direction and @warrior.direction_of(space) == direction
        priority_covered = true
      end
    end
    #insert priority direction above others
    if direction and not priority_covered
      priority = @warrior.feel(direction)
      if priority.empty? 
        empty_spaces.insert(0,priority)
      end
    end
    return empty_spaces
  end
  
  #return array of captives or ticking captives
  def find_captives(ticking_captives=nil)
    captives = []
    @warrior.listen.each do |space|
      if ticking_captives
        if space.ticking?
          captives.push(space)
        end
      elsif space.captive?
        captives.push(space)
      end
    end
    return captives
  end
  
  # determine if the area is good for a bomb
  # no captives should be harmed
  # more than 2 enemies should be in bomb range
  # for self-damage to be worth-it
  # bomb range is:
  #       two spaces forward
  #       one space left-forward
  #       one space right-forward
  #       current space (self-damage
  def could_bomb
    bomb_range_spaces = []
    # spaces with range 2 in a given direction
    @warrior.listen.each do |unit|
      if @warrior.distance_of(unit) >= 2 and not unit.captive? and @warrior.direction_of(unit) == :forward
        bomb_range_spaces.push(unit)
      end
    end
    return bomb_range_spaces.count > 1
  end
end
