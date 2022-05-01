
function get-replied-to ($obj)
{
    $res = $obj.referenced_tweets | Where-Object 'type' -EQ 'replied_to'

    if ($res)
    {
        $res.id
    }
}

function get-by-id ($items, $id)
{
    $items | Where-Object 'id' -EQ $id
}

function get-user-by-id ($users, $id)
{
    $users | Where-Object 'id' -EQ $id
}

$Global:users = @()

function display-thread ($item, $indent)
{
    $user = get-user-by-id $users $item.author_id
    
    '{0} {1,4} {2,4} {3,4} {4}' -f 
        ('*' * $indent),
        $item.public_metrics.like_count,
        $item.public_metrics.reply_count,
        $item.public_metrics.retweet_count,
        $user.username
            
    $item.text -replace "`n", "`r`n"
        
    ''

    foreach ($elt in $item.replies | Sort-Object -Property @{ Expression = { $_.public_metrics.like_count } } -Descending)
    {
        display-thread $elt ($indent + 1)
    }
}

function tweet-thread-to-org-mode ($id)
{
    $result = twarc2 tweet $id | ConvertFrom-Json

    $replies = twarc2 conversation $id | ConvertFrom-Json
    
    $items = $result.data + $replies.data
        
    $Global:users = $replies.includes.users | Sort-Object -Unique username
    
    foreach ($elt in $items)
    {
        $elt | Add-Member -Name 'replies' -Type NoteProperty -Value @()
    }
    
    foreach ($elt in $items)
    {
        $parent_id = get-replied-to $elt

        if ($parent_id)
        {
            $parent = get-by-id $items $parent_id

            $parent.replies += $elt
        }
    }
    
    display-thread $items[0] 1 > "$id.org"
}

# tweet-thread-to-org-mode 1520080172896055296

# tweet-thread-to-org-mode 1519833693447241728

# tweet-thread-to-org-mode 1520784507195969537

# tweet-thread-to-org-mode 1520366733399314432

# tweet-thread-to-org-mode 1520633450562134016