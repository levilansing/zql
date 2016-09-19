#!/usr/bin/env ruby

Dir.chdir __dir__
$LOAD_PATH << __dir__

require 'zql'

class ExampleTemplate < ZQL::Template
  def sql
    l("\n-- example from readme\n")

    select event.action, item.name, max(item.price).as(max_price), count('*').as(count)
    from events as event
    inner join order_items as item on event.order_item_id == item.id
    where category_expression('Electronics')
    group by event.action, item.name
    order by max_price
    limit 10
  end

  def category_expression(category)
    (item.category == s(category)).or(event.category == s(category))
  end
end

puts ExampleTemplate.new.compile

# ---------------------------------

class Template1 < ZQL::Template
  def sql
    l("\n-- subquery example from http://docs.aws.amazon.com/redshift/latest/dg/r_Subquery_examples.html\n")

    select qtr, sum(pricepaid).as(qtrsales), _{
      select sum(pricepaid)
      from sales join date on sales.dateid == date.dateid
      where (qtr == s(1)).and(year == 2008)
    }.as(q1sales)
    from sales join date on sales.dateid == date.dateid
    where (qtr == [s(2), s(3)]).and(year == 2008)
    group by qtr
    order by qtr
  end
end

puts Template1.new.compile

# ---------------------------------

class Template2 < ZQL::Template
  # for rubymine :/
  def select(*params)
    super
  end

  def sql
    l("\n-- with clause example from http://docs.aws.amazon.com/redshift/latest/dg/r_WITH_clause.html\n")

    with _{
      select venuename, venuecity, sum(pricepaid).as(venuename_sales)
      from sales, venue, event
      where (venue.venueid == event.venueid).and(event.eventid == sales.eventid)
      group by venuename, venuecity
    }.as(venu_sales), _{
      select venuename
      from venue_sales
      where venuename_sales > 800000
    }.as(top_venues)

    select venuename, venuecity, venuestate,
      sum(qtysold).as(venue_qty),
      sum(pricepaid).as(venue_sales)
    from sales, venue, event
    where (venue.venueid == event.venueid)
      .and(event.eventid == sales.eventid, venuename == [_{select venuename from top_venues}])
    group by venuename, venuecity, venuestate
    order by venuename
  end
end

puts Template2.new.compile

# ---------------------------------

class Template3 < ZQL::Template
  # for rubymine :/
  def select(*params)
    super
  end

  def sql
    l("\n-- another example from http://docs.aws.amazon.com/redshift/latest/dg/r_Join_examples.html\n")

    select catgroup1, sold, unsold
    from _{
      select catgroup, sum(qtysold).as(sold)
      from category.as(c), event.as(e), sales.as(s)
      where (c.catid == e.catid).and(e.eventid == s.eventid)
      group by catgroup
    }.as(f(:a, catgroup1, sold))
    join(_{
      select catgroup, (sum(numtickets) - sum(qtysold)).as(unsold)
      from category.as(c), event.as(e), sales.as(s), listing.as(l)
      where (c.catid == e.catid).and(e.eventid == s.eventid, s.listid == l.listid)
      group by catgroup
    }.as(f(:b, catgroup2, unsold))).on(a.catgroup1 == b.catgroup2)
    order by 1

  end
end

puts Template3.new.compile
