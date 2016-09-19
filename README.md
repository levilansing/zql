# ZQL - Proof of Concept

A proof of concept DSL for writing readable Amazon Redshift flavored SQL directly in ruby.

Run the examples in ruby 2.3+ with `ruby examples.rb`

## Example 

```ruby
class ExampleTemplate < ZQL::Template
  def sql
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

```

Generates the following output:

```sql
select event.action, item.name, max(item.price) as max_price, count(*) as count
from events as event
inner join order_items as item on event.order_item_id = item.id
where (item.category = 'Electronics') or (event.category = 'Electronics')
group by event.action, item.name
order by max_price
limit 10;
```

### Limitations

This proof of concept was designed to allow you to write SQL templates with as close to pure SQL as possible
while still writing ruby so you can call out to helpers, other templates, or pass in a context. It is also
intended to map the sql into known classes for intelligent compiling, but this part is a WIP.

It's currently limited to select queries with commonly used sql functions and syntax. Most unsupported 
language constructs should be possible since the DSL assumes a chain of generic keywords until it sees 
something it understands and also allows direct injections using literals 
(`l('literally add this text to my sql output')`).
